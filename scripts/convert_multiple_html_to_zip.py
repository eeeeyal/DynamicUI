#!/usr/bin/env python3
"""
Convert multiple HTML files to a single ZIP file with multiple screens
Each HTML file becomes a separate screen with navigation between them
"""
import json
import re
import zipfile
from pathlib import Path
from bs4 import BeautifulSoup, Tag, NavigableString


class MultiScreenConverter:
    def __init__(self, html_dir: str, output_dir: str):
        self.html_dir = Path(html_dir)
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)
        
        self.runtime = {
            "app": {},
            "state": {},
            "screens": {},
            "actions": {}
        }
        
        # Screen names mapping
        self.screen_names = {
            "home": "בית",
            "map": "מפה",
            "image": "תמונה",
            "camera": "מצלמה",
            "contacts": "אנשי קשר",
            "notifications": "התראות",
            "storage": "אחסון",
            "sensors": "חיישנים",
            "network": "רשת",
            "settings": "הגדרות"
        }

    def extract_vue_state(self, soup):
        """Extract Vue state from script tags"""
        scripts = soup.find_all("script")
        for script in scripts:
            if script.string and "data()" in script.string:
                match = re.search(
                    r"data\s*\(\)\s*{[^}]*return\s*{(.*?)}\s*}",
                    script.string,
                    re.DOTALL
                )
                if match:
                    raw = match.group(1)
                    state = {}
                    pairs = re.findall(r"(\w+)\s*:\s*([^,\n]+)", raw)
                    for key, value in pairs:
                        value = value.strip()
                        if value in ["true", "false"]:
                            state[key] = value == "true"
                        elif value == "null":
                            state[key] = None
                        elif re.match(r"^\d+$", value):
                            state[key] = int(value)
                        elif re.match(r"^\d+\.\d+$", value):
                            state[key] = float(value)
                        elif value.startswith(("'", '"')):
                            state[key] = value.strip("'\"")
                        else:
                            state[key] = "DYNAMIC"
                    return state
        return {}

    def parse_tailwind(self, classes):
        """Parse Tailwind CSS classes to style and layout"""
        style = {}
        layout = {}
        
        if not classes:
            return style, layout
            
        for c in classes:
            if not isinstance(c, str):
                continue
                
            # Padding
            if c.startswith("p-"):
                try:
                    style["padding"] = int(c.split("-")[1]) * 4
                except:
                    pass
            
            # Gap
            if c.startswith("gap-"):
                try:
                    layout["gap"] = int(c.split("-")[1]) * 4
                except:
                    pass
            
            # Rounded
            if c.startswith("rounded"):
                style["radius"] = 16
            
            # Shadow
            if c.startswith("shadow"):
                style["elevation"] = 4
            
            # Grid
            if c.startswith("grid-cols-"):
                layout["type"] = "grid"
                try:
                    layout["columns"] = int(c.split("-")[-1])
                except:
                    layout["columns"] = 2
            
            # Flex
            if c == "flex":
                layout["type"] = "row"
            if c == "flex-col":
                layout["type"] = "column"
            
            if c.startswith("justify-"):
                layout["mainAxis"] = c.split("-")[1]
            
            if c.startswith("items-"):
                layout["crossAxis"] = c.split("-")[1]
            
            # Background
            if c == "bg-white":
                style["background"] = "#FFFFFF"
            elif c.startswith("bg-"):
                # Map common Tailwind colors
                color_map = {
                    "bg-blue-500": "#3B82F6",
                    "bg-green-500": "#10B981",
                    "bg-purple-500": "#8B5CF6",
                    "bg-red-500": "#EF4444",
                    "bg-yellow-500": "#F59E0B",
                    "bg-indigo-500": "#6366F1",
                    "bg-pink-500": "#EC4899",
                    "bg-teal-500": "#14B8A6",
                    "bg-orange-500": "#F97316",
                    "bg-gray-500": "#6B7280",
                }
                if c in color_map:
                    style["background"] = color_map[c]
        
        return style, layout

    def convert_element(self, element):
        """Convert HTML element to JSON widget"""
        if not isinstance(element, Tag):
            return None
        
        tag = element.name.lower() if element.name else None
        if not tag:
            return None
            
        classes = element.get("class", [])
        class_str = " ".join(classes) if isinstance(classes, list) else str(classes)
        style, layout = self.parse_tailwind(classes)
        
        node = {}
        
        # Visibility
        visible = element.get("v-if") or element.get("v-show")
        if visible:
            node["visibleIf"] = visible
        
        # Click action
        click = element.get("onclick") or element.get("@click")
        if click:
            # Extract navigate function call
            import re
            nav_match = re.search(r"navigate\(['\"](.*?)['\"]\)", click)
            if nav_match:
                route = nav_match.group(1)
                action_name = f"navigate_{route}"
                self.runtime["actions"][action_name] = {
                    "type": "navigation",
                    "route": route
                }
                node["action"] = action_name
        
        # v-model binding
        model = element.get("v-model")
        if model:
            node["bindTo"] = model
        
        # Tag mapping with better detection
        if tag == "header":
            node["type"] = "appBar"
            h1 = element.find("h1")
            if h1:
                node["title"] = h1.get_text(strip=True)
            else:
                node["title"] = element.get_text(strip=True)
        elif tag == "nav":
            # Navigation menu - convert to container (the inner div will be row)
            node["type"] = "container"
            # Apply nav styles
            if "bg-white" in class_str:
                if "style" not in node:
                    node["style"] = {}
                node["style"]["background"] = "#FFFFFF"
            if "shadow-lg" in class_str:
                if "style" not in node:
                    node["style"] = {}
                node["style"]["elevation"] = 4
            if "p-4" in class_str:
                if "style" not in node:
                    node["style"] = {}
                node["style"]["padding"] = 16
            if "mb-4" in class_str:
                # Margin bottom will be handled by gap in parent column
                pass
        elif tag == "button":
            node["type"] = "button"
            node["text"] = element.get_text(strip=True)
            # Extract background color from classes
            for bg_class in ["bg-blue-500", "bg-green-500", "bg-purple-500", "bg-red-500", 
                           "bg-yellow-500", "bg-indigo-500", "bg-pink-500", "bg-teal-500", 
                           "bg-orange-500", "bg-gray-500"]:
                if bg_class in class_str:
                    color_map = {
                        "bg-blue-500": "#3B82F6",
                        "bg-green-500": "#10B981",
                        "bg-purple-500": "#8B5CF6",
                        "bg-red-500": "#EF4444",
                        "bg-yellow-500": "#F59E0B",
                        "bg-indigo-500": "#6366F1",
                        "bg-pink-500": "#EC4899",
                        "bg-teal-500": "#14B8A6",
                        "bg-orange-500": "#F97316",
                        "bg-gray-500": "#6B7280",
                    }
                    if "style" not in node:
                        node["style"] = {}
                    node["style"]["background"] = color_map[bg_class]
                    break
        elif tag == "input":
            node["type"] = "input"
            node["inputType"] = element.get("type", "text")
            placeholder = element.get("placeholder")
            if placeholder:
                node["placeholder"] = placeholder
        elif tag == "select":
            node["type"] = "select"
            node["options"] = [
                opt.get_text(strip=True)
                for opt in element.find_all("option")
            ]
        elif tag == "textarea":
            node["type"] = "textarea"
        elif tag == "main":
            node["type"] = "container"
        elif tag in ["h1", "h2", "h3"]:
            node["type"] = "text"
            node["value"] = element.get_text(strip=True)
            if tag == "h1":
                node["fontSize"] = 24
                node["fontWeight"] = "bold"
            elif tag == "h2":
                node["fontSize"] = 20
                node["fontWeight"] = "bold"
            elif tag == "h3":
                node["fontSize"] = 18
                node["fontWeight"] = "bold"
        elif tag == "p":
            node["type"] = "text"
            node["value"] = element.get_text(strip=True)
        elif tag == "div":
            # Check for grid
            if "grid" in class_str and "grid-cols" in class_str:
                import re
                cols_match = re.search(r"grid-cols-(\d+)", class_str)
                node["type"] = "grid"
                node["columns"] = int(cols_match.group(1)) if cols_match else 2
            elif "flex" in class_str:
                if "flex-col" in class_str:
                    node["type"] = "column"
                else:
                    node["type"] = "row"
                    # Set alignment from classes
                    if "justify-center" in class_str:
                        node["mainAxis"] = "center"
                    elif "justify-between" in class_str:
                        node["mainAxis"] = "space-between"
                    if "gap-" in class_str:
                        import re
                        gap_match = re.search(r"gap-(\d+)", class_str)
                        if gap_match:
                            node["gap"] = int(gap_match.group(1)) * 4  # Tailwind gap units
            else:
                node["type"] = "container"
        else:
            node["type"] = layout.get("type", "container")
        
        # Attach style
        if style:
            node["style"] = style
        
        # Layout properties
        for k in ["columns", "gap", "mainAxis", "crossAxis"]:
            if k in layout:
                node[k] = layout[k]
        
        # Children - but skip text nodes that are already in parent
        children = self.convert_children(element)
        if children:
            # Filter out duplicate text nodes
            filtered_children = []
            for child in children:
                if child.get("type") == "text":
                    # Only add if it's not empty and meaningful
                    value = child.get("value", "")
                    if value and value.strip():
                        filtered_children.append(child)
                else:
                    filtered_children.append(child)
            if filtered_children:
                node["children"] = filtered_children
        
        return node if node.get("type") else None

    def convert_children(self, element):
        """Convert element children"""
        children = []
        for child in element.children:
            if isinstance(child, NavigableString):
                # Skip whitespace-only text nodes
                text = str(child).strip()
                if text and len(text) > 1:  # Only meaningful text
                    children.append({
                        "type": "text",
                        "value": text
                    })
            elif isinstance(child, Tag):
                converted = self.convert_element(child)
                if converted:
                    children.append(converted)
        return children

    def _camel_to_snake(self, name):
        """Convert camelCase to snake_case"""
        name = name.replace("()", "").replace("(", "").replace(")", "")
        s1 = re.sub('(.)([A-Z][a-z]+)', r'\1_\2', name)
        return re.sub('([a-z0-9])([A-Z])', r'\1_\2', s1).lower()

    def _extract_route_from_navigate(self, click_str):
        """Extract route name from navigate('route')"""
        match = re.search(r"navigate\(['\"](.*?)['\"]\)", click_str)
        return match.group(1) if match else None

    def convert_html_file(self, html_file: Path):
        """Convert a single HTML file to screen JSON"""
        with open(html_file, "r", encoding="utf-8") as f:
            html = f.read()
        
        soup = BeautifulSoup(html, "html.parser")
        
        # Extract state
        state = self.extract_vue_state(soup)
        self.runtime["state"].update(state)
        
        # Extract screen name from filename
        screen_name = html_file.stem
        
        # Convert body content
        body = soup.body
        if not body:
            return None
        
        # Separate header, nav, and main content
        header = body.find("header")
        nav = body.find("nav")
        main = body.find("main")
        
        layout_children = []
        
        # Convert header to appBar (but don't add to layout, handle separately)
        app_bar_data = None
        if header:
            app_bar_converted = self.convert_element(header)
            if app_bar_converted:
                app_bar_data = app_bar_converted
        
        # Convert nav to row with buttons
        if nav:
            nav_converted = self.convert_element(nav)
            if nav_converted:
                layout_children.append(nav_converted)
        
        # Convert main content
        if main:
            main_converted = self.convert_element(main)
            if main_converted:
                layout_children.append(main_converted)
        else:
            # If no main, convert all other body children
            for child in body.children:
                if isinstance(child, Tag) and child.name not in ["header", "nav", "script"]:
                    converted = self.convert_element(child)
                    if converted:
                        layout_children.append(converted)
        
        # Create screen JSON
        screen_json = {
            "type": "screen",
            "id": screen_name,
        }
        
        # Add appBar if exists
        if app_bar_data:
            screen_json["appBar"] = app_bar_data
        
        # Add layout
        screen_json["layout"] = {
            "type": "column",
            "children": layout_children
        }
        
        self.runtime["screens"][screen_name] = screen_json
        return screen_json

    def build_zip(self):
        """Build ZIP file with all screens"""
        app_json = {
            "appId": "multi_screen_app",
            "version": "1.0.0",
            "initialRoute": "home",
            "rtl": True
        }
        
        # Create routes.json
        routes = {}
        for screen_name in self.runtime["screens"].keys():
            routes[screen_name] = f"screens/{screen_name}.json"
        
        zip_path = self.output_dir / "multi_screen_app.zip"
        
        with zipfile.ZipFile(zip_path, "w") as z:
            z.writestr("app.json", json.dumps(app_json, indent=2, ensure_ascii=False))
            z.writestr("state.json", json.dumps(self.runtime["state"], indent=2, ensure_ascii=False))
            z.writestr("actions.json", json.dumps(self.runtime["actions"], indent=2, ensure_ascii=False))
            z.writestr("routes.json", json.dumps(routes, indent=2, ensure_ascii=False))
            
            # Write each screen as separate JSON file
            for screen_name, screen_json in self.runtime["screens"].items():
                z.writestr(
                    f"screens/{screen_name}.json",
                    json.dumps(screen_json, indent=2, ensure_ascii=False)
                )
        
        print(f"ZIP created: {zip_path}")
        return zip_path

    def run(self):
        """Convert all HTML files in directory"""
        html_files = list(self.html_dir.glob("*.html"))
        
        if not html_files:
            print(f"No HTML files found in {self.html_dir}")
            return
        
        print(f"Found {len(html_files)} HTML files")
        
        for html_file in html_files:
            print(f"Converting {html_file.name}...")
            self.convert_html_file(html_file)
        
        print("Building ZIP...")
        zip_path = self.build_zip()
        print(f"Done! ZIP created at: {zip_path}")


if __name__ == "__main__":
    import sys
    
    html_dir = sys.argv[1] if len(sys.argv) > 1 else "./html_screens"
    output_dir = sys.argv[2] if len(sys.argv) > 2 else "./output"
    
    converter = MultiScreenConverter(html_dir, output_dir)
    converter.run()

