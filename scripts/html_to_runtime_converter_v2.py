#!/usr/bin/env python3
import os
import json
import re
import zipfile
from pathlib import Path
from bs4 import BeautifulSoup, Tag
from typing import Dict, Any


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

    # ==========================
    # 1️⃣ Extract Vue State
    # ==========================
    def extract_vue_state(self):
        script_tags = self.soup.find_all("script")
    
        for script in script_tags:
            if script.string and "data()" in script.string:
            
                match = re.search(
                    r"data\s*\(\)\s*{[^}]*return\s*{(.*?)}\s*}",
                    script.string,
                    re.DOTALL
                )
    
                if match:
                    raw_state = match.group(1)
    
                    state = {}
    
                    # מחלץ שורות כמו: key: value,
                    pairs = re.findall(r"(\w+)\s*:\s*([^,\n]+)", raw_state)
    
                    for key, value in pairs:
                        value = value.strip()
    
                        # טיפול בערכים פשוטים בלבד
                        if value in ["true", "false"]:
                            state[key] = value == "true"
                        elif value == "null":
                            state[key] = None
                        elif re.match(r"^\d+$", value):
                            state[key] = int(value)
                        elif re.match(r"^\d+\.\d+$", value):
                            state[key] = float(value)
                        elif value.startswith("'") or value.startswith('"'):
                            state[key] = value.strip("'\"")
                        else:
                            # אם זה משהו מורכב (array / object / function)
                            state[key] = "DYNAMIC"
    
                    self.runtime["state"] = state
                    print("✅ Vue state extracted safely")



    # ==========================
    # 2️⃣ Extract Layout
    # ==========================
    def convert_element(self, element):

        if not isinstance(element, Tag):
            return None

        tag = element.name.lower()

        # Header → AppBar
        if tag == "header":
            return {
                "type": "appBar",
                "title": element.get_text(strip=True)
            }

        # Grid → Row
        if "grid-cols-2" in element.get("class", []):
            return {
                "type": "row",
                "children": self.convert_children(element)
            }

        # Flex column → Column
        if "flex-col" in element.get("class", []):
            return {
                "type": "column",
                "children": self.convert_children(element)
            }

        if tag == "button":
            action = element.get("@click")
            if action:
                self.runtime["actions"][action] = {
                    "type": "logic",
                    "expression": action
                }

            return {
                "type": "button",
                "text": element.get_text(strip=True),
                "action": action
            }

        if tag == "input":
            model = element.get("v-model")
            return {
                "type": "input",
                "bindTo": model,
                "inputType": element.get("type", "text")
            }

        if tag in ["h1", "h2", "h3", "p", "span"]:
            return {
                "type": "text",
                "value": element.get_text(strip=True)
            }

        return {
            "type": "container",
            "children": self.convert_children(element)
        }

    def convert_children(self, element):
        children = []
        for child in element.children:
            converted = self.convert_element(child)
            if converted:
                children.append(converted)
        return children

    # ==========================
    # 3️⃣ Build Screen
    # ==========================
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

    # ==========================
    # 4️⃣ Create ZIP
    # ==========================
    def build_zip(self):

        app_json = {
            "appId": self.html_path.stem,
            "version": "1.0.0",
            "initialRoute": "main"
        }

        zip_path = self.output_dir / f"{self.html_path.stem}.zip"

        with zipfile.ZipFile(zip_path, "w") as z:

            z.writestr("app.json", json.dumps(app_json, indent=2, ensure_ascii=False))
            z.writestr("state.json", json.dumps(self.runtime["state"], indent=2, ensure_ascii=False))
            z.writestr("actions.json", json.dumps(self.runtime["actions"], indent=2, ensure_ascii=False))
            z.writestr("screens/main.json", json.dumps(self.runtime["screens"]["main"], indent=2, ensure_ascii=False))

        print(f"✅ ZIP created: {zip_path}")

    # ==========================
    # RUN
    # ==========================
    def run(self):
        print("🔍 Extracting Vue state")
        self.extract_vue_state()

        print("🧱 Building layout")
        self.extract_screen()

        print("📦 Creating ZIP")
        self.build_zip()


if __name__ == "__main__":
    converter = RuntimeConverter("index.html", "./output")
    converter.run()
