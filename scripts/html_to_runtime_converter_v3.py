#!/usr/bin/env python3
import json
import re
import zipfile
from pathlib import Path
from bs4 import BeautifulSoup, Tag


class RuntimeConverter:

    def __init__(self, html_path: str, output_dir: str):
        self.html_path = Path(html_path)
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)

        with open(self.html_path, "r", encoding="utf-8") as f:
            self.html = f.read()

        self.soup = BeautifulSoup(self.html, "html.parser")

        self.runtime = {
            "app": {},
            "state": {},
            "screens": {},
            "actions": {}
        }

    # =========================================================
    # 1️⃣ Extract Vue State (Safe)
    # =========================================================
    def extract_vue_state(self):
        scripts = self.soup.find_all("script")

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

                    self.runtime["state"] = state
                    print("✅ State extracted")

    # =========================================================
    # 2️⃣ Tailwind → Style Engine
    # =========================================================
    def parse_tailwind(self, classes):
        style = {}
        layout = {}

        for c in classes:

            # Padding
            if c.startswith("p-"):
                style["padding"] = int(c.split("-")[1]) * 4

            # Gap
            if c.startswith("gap-"):
                layout["gap"] = int(c.split("-")[1]) * 4

            # Rounded
            if c.startswith("rounded"):
                style["radius"] = 16

            # Shadow
            if c.startswith("shadow"):
                style["elevation"] = 4

            # Grid
            if c.startswith("grid-cols-"):
                layout["type"] = "grid"
                layout["columns"] = int(c.split("-")[-1])

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

        return style, layout

    # =========================================================
    # 3️⃣ Convert Element
    # =========================================================
    def convert_element(self, element):

        if not isinstance(element, Tag):
            return None

        tag = element.name.lower()
        classes = element.get("class", [])

        style, layout = self.parse_tailwind(classes)

        node = {}

        # Visibility
        visible = element.get("v-if") or element.get("v-show")
        if visible:
            node["visibleIf"] = visible

        # Click
        click = element.get("@click")
        if click:
            self.runtime["actions"][click] = {
                "type": "logic",
                "expression": click
            }
            node["action"] = click

        # v-model
        model = element.get("v-model")
        if model:
            node["bindTo"] = model

        # =====================================================
        # Tag mapping
        # =====================================================

        if tag == "header":
            node["type"] = "appBar"
            node["title"] = element.get_text(strip=True)

        elif tag == "button":
            node["type"] = "button"
            node["text"] = element.get_text(strip=True)

        elif tag == "input":
            node["type"] = "input"
            node["inputType"] = element.get("type", "text")

        elif tag == "select":
            node["type"] = "select"
            node["options"] = [
                opt.get_text(strip=True)
                for opt in element.find_all("option")
            ]

        elif tag == "textarea":
            node["type"] = "textarea"

        elif tag in ["h1", "h2", "h3", "p", "span"]:
            node["type"] = "text"
            node["value"] = element.get_text(strip=True)

        else:
            node["type"] = layout.get("type", "container")

        # Attach style
        if style:
            node["style"] = style

        # Layout properties
        for k in ["columns", "gap", "mainAxis", "crossAxis"]:
            if k in layout:
                node[k] = layout[k]

        # Children
        children = self.convert_children(element)
        if children:
            node["children"] = children

        return node

    def convert_children(self, element):
        children = []
        for child in element.children:
            converted = self.convert_element(child)
            if converted:
                children.append(converted)
        return children

    # =========================================================
    # 4️⃣ Build Screen
    # =========================================================
    def extract_screen(self):
        body = self.soup.body
        layout = self.convert_children(body)

        self.runtime["screens"]["main"] = {
            "type": "screen",
            "id": "main",
            "layout": {
                "type": "column",
                "children": layout
            }
        }

    # =========================================================
    # 5️⃣ Build ZIP
    # =========================================================
    def build_zip(self):

        app_json = {
            "appId": self.html_path.stem,
            "version": "1.0.0",
            "initialRoute": "main",
            "rtl": True
        }

        zip_path = self.output_dir / f"{self.html_path.stem}.zip"

        with zipfile.ZipFile(zip_path, "w") as z:

            z.writestr("app.json", json.dumps(app_json, indent=2, ensure_ascii=False))
            z.writestr("state.json", json.dumps(self.runtime["state"], indent=2, ensure_ascii=False))
            z.writestr("actions.json", json.dumps(self.runtime["actions"], indent=2, ensure_ascii=False))
            z.writestr("screens/main.json", json.dumps(self.runtime["screens"]["main"], indent=2, ensure_ascii=False))

        print(f"✅ ZIP created: {zip_path}")

    # =========================================================
    def run(self):
        print("🔍 Extracting state")
        self.extract_vue_state()

        print("🧱 Converting layout")
        self.extract_screen()

        print("📦 Building ZIP")
        self.build_zip()


if __name__ == "__main__":
    import sys

    if len(sys.argv) < 2:
        print("Usage: python html_to_runtime_converter_v3.py <html_file> [output_dir]")
        exit()

    html_file = sys.argv[1]
    output_dir = sys.argv[2] if len(sys.argv) > 2 else "./output"

    converter = RuntimeConverter(html_file, output_dir)
    converter.run()
