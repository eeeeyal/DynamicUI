#!/usr/bin/env python3
"""
HTML to ZIP Converter
ממיר HTML לקובץ ZIP בפורמט Dynamic UI Runtime Engine

הסקריפט מנתח HTML וממיר אותו למבנה JSON עם מסכים נפרדים,
תוך שמירה על הפריסה המדויקת כמו בדפדפן.

שימוש:
    python html_to_zip_converter.py <input_dir> [output_dir]
    
דוגמה:
    python html_to_zip_converter.py ./html_files
    # ישאל איפה ליצור את התיקייה החדשה
"""

import os
import json
import re
import zipfile
from pathlib import Path
from bs4 import BeautifulSoup, NavigableString, Tag
from typing import Dict, List, Optional, Any
from urllib.parse import urlparse

class HTMLToZipConverter:
    """ממיר HTML לקובץ ZIP בפורמט Dynamic UI"""
    
    def __init__(self, html_file: str, output_dir: str = None, app_id: str = None):
        """
        Args:
            html_file: נתיב לקובץ HTML
            output_dir: תיקיית פלט (אם None, ישאל את המשתמש)
            app_id: מזהה האפליקציה (אם None, יקח משם הקובץ)
        """
        self.html_file = Path(html_file)
        self.app_id = app_id or self.html_file.stem
        
        # תיקיית פלט
        if output_dir:
            self.output_dir = Path(output_dir)
        else:
            # שאילת המשתמש
            self.output_dir = self._ask_output_directory()
        
        self.output_dir.mkdir(parents=True, exist_ok=True)
        
        # תיקיות עבודה
        self.app_dir = self.output_dir / self.app_id
        self.screens_dir = self.app_dir / "screens"
        self.assets_dir = self.app_dir / "assets"
        
        # נתונים שנאספים
        self.screens = {}
        self.actions = {}
        self.routes = {}
        self.styles = {}
        self.current_screen_id = None
        
        # טעינת HTML
        with open(self.html_file, 'r', encoding='utf-8') as f:
            self.html_content = f.read()
            self.soup = BeautifulSoup(self.html_content, 'html.parser')
    
    def _ask_output_directory(self) -> Path:
        """שואל את המשתמש איפה ליצור את התיקייה"""
        print("\n" + "="*60)
        print("📁 בחירת תיקיית פלט")
        print("="*60)
        default_dir = Path.cwd() / "converted_apps"
        print(f"\nתיקייה ברירת מחדל: {default_dir}")
        user_input = input("הזן נתיב לתיקיית פלט (Enter לברירת מחדל): ").strip()
        
        if user_input:
            output_path = Path(user_input)
        else:
            output_path = default_dir
        
        output_path.mkdir(parents=True, exist_ok=True)
        return output_path
    
    def convert(self):
        """המרה ראשית - ממיר את ה-HTML ל-ZIP"""
        print(f"\n🔄 מתחיל המרת {self.html_file.name}...")
        
        # יצירת תיקיות
        self.app_dir.mkdir(parents=True, exist_ok=True)
        self.screens_dir.mkdir(parents=True, exist_ok=True)
        self.assets_dir.mkdir(parents=True, exist_ok=True)
        
        # ניתוח HTML
        self._extract_styles()
        self._extract_actions()
        self._extract_screens()
        
        # יצירת קבצי הגדרה
        self._create_app_json()
        self._create_routes_json()
        self._create_styles_json()
        self._create_actions_json()
        
        # יצירת ZIP
        output_zip = self.output_dir / f"{self.app_id}.zip"
        self._create_zip(output_zip)
        
        print(f"✅ הושלם! קובץ ZIP נוצר: {output_zip}")
        print(f"📁 תיקיית JSONs: {self.app_dir}")
    
    def _extract_styles(self):
        """חילוץ הגדרות עיצוב מה-HTML"""
        print("🎨 מחלץ הגדרות עיצוב...")
        
        # חילוץ צבעים מ-Tailwind classes ו-CSS
        primary_color = "#4f46e5"  # indigo-600
        secondary_color = "#7c3aed"  # purple-600
        bg_color = "#f3f4f6"  # gray-100
        
        # חיפוש צבעים ב-CSS
        style_tags = self.soup.find_all('style')
        for style in style_tags:
            style_text = style.get_text()
            # חיפוש צבעים ב-CSS
            if 'indigo-600' in style_text or 'indigo' in style_text:
                primary_color = "#4f46e5"
            if 'purple-600' in style_text or 'purple' in style_text:
                secondary_color = "#7c3aed"
        
        self.styles = {
            "primaryColor": primary_color,
            "secondaryColor": secondary_color,
            "backgroundColor": bg_color,
            "buttonRadius": 12
        }
    
    def _extract_actions(self):
        """חילוץ פעולות מה-HTML (כפתורים עם @click)"""
        print("🔧 מחלץ פעולות...")
        
        # חיפוש כפתורים עם @click
        buttons = self.soup.find_all(['button', 'a'])
        action_counter = 1
        
        for button in buttons:
            if not isinstance(button, Tag):
                continue
            onclick = button.get('@click') or button.get('onclick')
            if onclick and isinstance(onclick, str):
                # ניקוי ה-action
                action_name = onclick.strip()
                # הסרת Vue.js syntax
                action_name = re.sub(r'activeTab\s*=\s*[\'"](\w+)[\'"]', r'goTo\1', action_name)
                action_name = re.sub(r'(\w+)\(', r'\1', action_name)
                action_name = action_name.replace('()', '').strip()
                
                if not action_name:
                    action_name = f"action{action_counter}"
                    action_counter += 1
                
                # יצירת action ID
                action_id = self._camel_to_snake(action_name)
                
                # זיהוי סוג פעולה
                if 'goTo' in action_id or 'navigate' in action_id:
                    # פעולת ניווט
                    route = action_id.replace('go_to_', '').replace('goTo', '')
                    self.actions[action_id] = {
                        "type": "navigation",
                        "route": route
                    }
                else:
                    # פעולת API (mock)
                    self.actions[action_id] = {
                        "type": "api",
                        "method": "POST",
                        "endpoint": f"/api/{action_id}"
                    }
    
    def _extract_screens(self):
        """חילוץ מסכים מה-HTML"""
        print("📱 מחלץ מסכים...")
        
        # חיפוש טאבים (v-show או @click עם activeTab)
        tabs = self._find_tabs()
        
        if tabs:
            # יצירת מסך אחד עם טאבים (כמו בדפדפן)
            self._create_single_screen_with_tabs(tabs)
        else:
            # אין טאבים - יצירת מסך יחיד
            self._create_single_screen()
    
    def _find_tabs(self) -> Dict[str, Dict]:
        """מזהה טאבים ב-HTML"""
        tabs = {}
        
        # חיפוש כפתורי טאבים
        buttons = self.soup.find_all('button')
        for button in buttons:
            if not isinstance(button, Tag):
                continue
            onclick = button.get('@click') or button.get('onclick', '')
            if not onclick:
                continue
            match = re.search(r'activeTab\s*=\s*[\'"](\w+)[\'"]', onclick)
            if match:
                tab_id = match.group(1)
                tab_text = button.get_text(strip=True)
                tabs[tab_id] = {
                    'text': tab_text,
                    'button': button
                }
        
        # חיפוש divs עם v-show
        divs = self.soup.find_all('div', {'v-show': True})
        for div in divs:
            if not isinstance(div, Tag):
                continue
            v_show = div.get('v-show', '')
            if not v_show:
                continue
            match = re.search(r'activeTab\s*===\s*[\'"](\w+)[\'"]', v_show)
            if match:
                tab_id = match.group(1)
                if tab_id not in tabs:
                    tabs[tab_id] = {
                        'text': tab_id.title(),
                        'content': div
                    }
        
        return tabs
    
    def _create_home_screen(self, tabs: Dict[str, Dict]):
        """יוצר מסך ראשי עם כפתורי ניווט"""
        print("🏠 יוצר מסך ראשי...")
        
        # חילוץ כותרת מה-header
        header = self.soup.find('header')
        title = "מסך ראשי"
        subtitle = ""
        
        if header:
            h1 = header.find('h1')
            if h1:
                title = h1.get_text(strip=True)
            p = header.find('p')
            if p:
                subtitle = p.get_text(strip=True)
        
        # יצירת כפתורי ניווט
        buttons = []
        for tab_id, tab_info in tabs.items():
            action_id = f"goTo{tab_id.capitalize()}"
            buttons.append({
                "type": "button",
                "text": tab_info['text'],
                "action": action_id
            })
            
            # הוספת action אם לא קיים
            if action_id not in self.actions:
                self.actions[action_id] = {
                    "type": "navigation",
                    "route": tab_id
                }
        
        # יצירת מסך ראשי
        screen_json = {
            "type": "screen",
            "id": "home",
            "appBar": {
                "title": title
            },
            "body": {
                "type": "column",
                "children": [
                    {
                        "type": "text",
                        "value": subtitle if subtitle else "ברוך הבא",
                        "fontSize": 18,
                        "color": "#6b7280"
                    }
                ] + buttons
            }
        }
        
        self.screens["home"] = screen_json
        self.routes["home"] = "screens/home.json"
    
    def _create_screen_from_tab(self, tab_id: str, tab_info: Dict):
        """יוצר מסך מתוכן טאב"""
        print(f"📄 יוצר מסך: {tab_id}...")
        
        # חילוץ תוכן הטאב
        content_div = None
        if 'content' in tab_info:
            content_div = tab_info['content']
        else:
            # חיפוש div עם v-show
            divs = self.soup.find_all('div', {'v-show': True})
            for div in divs:
                v_show = div.get('v-show', '')
                if tab_id in v_show:
                    content_div = div
                    break
        
        if not content_div:
            # יצירת מסך ריק
            content_div = self.soup.new_tag('div')
        
        # המרת תוכן הטאב ל-JSON
        children = self._convert_element_to_json(content_div)
        
        # יצירת מסך
        screen_json = {
            "type": "screen",
            "id": tab_id,
            "appBar": {
                "title": tab_info['text']
            },
            "body": {
                "type": "column",
                "children": children + [
                    {
                        "type": "button",
                        "text": "← חזרה",
                        "action": "goToHome"
                    }
                ]
            }
        }
        
        self.screens[tab_id] = screen_json
        self.routes[tab_id] = f"screens/{tab_id}.json"
        
        # הוספת action לחזרה אם לא קיים
        if "goToHome" not in self.actions:
            self.actions["goToHome"] = {
                "type": "navigation",
                "route": "home"
            }
    
    def _create_single_screen_with_tabs(self, tabs: Dict[str, Dict]):
        """יוצר מסך יחיד עם טאבים (כמו בדפדפן)"""
        print("📄 יוצר מסך יחיד עם טאבים...")
        
        # חילוץ header
        header = self.soup.find('header')
        title = "מסך ראשי"
        if header:
            h1 = header.find('h1')
            if h1:
                title = h1.get_text(strip=True)
        
        # חילוץ תוכן הטאבים
        tab_contents = []
        for tab_id, tab_info in tabs.items():
            content_div = None
            if 'content' in tab_info:
                content_div = tab_info['content']
            else:
                # חיפוש div עם v-show
                divs = self.soup.find_all('div', {'v-show': True})
                for div in divs:
                    v_show = div.get('v-show', '')
                    if tab_id in v_show:
                        content_div = div
                        break
            
            if content_div:
                children = self._convert_element_to_json(content_div)
                tab_contents.append({
                    "label": tab_info.get('text', tab_id.title()),
                    "content": {
                        "type": "column",
                        "children": children
                    }
                })
        
        # חילוץ קונסולת פלט (אם קיימת)
        console_content = None
        console_div = self.soup.find('div', class_=re.compile(r'console|output', re.I))
        if not console_div:
            # חיפוש div עם bg-gray-900 (קונסולה)
            console_div = self.soup.find('div', class_=re.compile(r'bg-gray-900|bg-black', re.I))
        
        if console_div:
            console_text = console_div.get_text(strip=True) or "Output will appear here..."
            console_content = {
                "type": "console",
                "title": "Output",
                "content": console_text,
                "showClearButton": True
            }
        
        # יצירת body עם grid (2 עמודות: טאבים + קונסולה)
        body_children = []
        
        if tab_contents:
            body_children.append({
                "type": "tabs",
                "tabs": tab_contents,
                "initialIndex": 0
            })
        
        if console_content:
            body_children.append(console_content)
        
        # אם יש 2 ילדים - יצירת grid, אחרת column
        if len(body_children) == 2:
            body = {
                "type": "grid",
                "columns": 2,
                "gap": 24.0,
                "children": body_children
            }
        else:
            body = {
                "type": "column",
                "children": body_children
            }
        
        screen_json = {
            "type": "screen",
            "id": "main",
            "appBar": {
                "title": title
            },
            "body": body
        }
        
        self.screens["main"] = screen_json
        self.routes["main"] = "screens/main.json"
        # גם home route
        self.routes["home"] = "screens/main.json"
    
    def _create_single_screen(self):
        """יוצר מסך יחיד מה-HTML"""
        print("📄 יוצר מסך יחיד...")
        
        body = self.soup.find('body')
        if not body:
            body = self.soup
        
        # המרת body ל-JSON
        children = self._convert_element_to_json(body)
        
        screen_json = {
            "type": "screen",
            "id": "main",
            "appBar": {
                "title": self.soup.find('title').get_text() if self.soup.find('title') else "מסך ראשי"
            },
            "body": {
                "type": "column",
                "children": children
            }
        }
        
        self.screens["main"] = screen_json
        self.routes["main"] = "screens/main.json"
    
    def _convert_element_to_json(self, element) -> List[Dict]:
        """ממיר אלמנט HTML ל-JSON structure"""
        children = []
        
        if not element:
            return children
        
        # עיבוד כל הילדים
        try:
            for child in element.children:
                # דילוג על NavigableString (טקסט פשוט) וקומנטרים
                if isinstance(child, NavigableString):
                    # אם זה טקסט משמעותי (לא רק רווחים), נוסיף אותו כ-text widget
                    text_content = str(child).strip()
                    if text_content and len(text_content) > 1:
                        children.append({
                            "type": "text",
                            "value": text_content
                        })
                    continue
                
                # דילוג על אובייקטים שאינם Tag
                if not isinstance(child, Tag):
                    continue
                
                # בדיקה ש-name קיים ולא None
                if child.name is None:
                    continue
                
                # בדיקה ש-name הוא string
                if not isinstance(child.name, str):
                    continue
                
                tag_name = child.name.lower()
            
            if tag_name == 'div':
                json_elem = self._parse_div(child)
                if json_elem:
                    children.append(json_elem)
            
            elif tag_name in ['h1', 'h2', 'h3', 'h4', 'h5', 'h6']:
                json_elem = self._parse_heading(child)
                if json_elem:
                    children.append(json_elem)
            
            elif tag_name == 'p':
                json_elem = self._parse_text(child)
                if json_elem:
                    children.append(json_elem)
            
            elif tag_name == 'button':
                json_elem = self._parse_button(child)
                if json_elem:
                    children.append(json_elem)
            
            elif tag_name == 'input':
                json_elem = self._parse_input(child)
                if json_elem:
                    children.append(json_elem)
            
            elif tag_name == 'label':
                json_elem = self._parse_label(child)
                if json_elem:
                    children.append(json_elem)
            
            elif tag_name == 'img':
                json_elem = self._parse_image(child)
                if json_elem:
                    children.append(json_elem)
            
            elif tag_name == 'form':
                json_elem = self._parse_form(child)
                if json_elem:
                    children.append(json_elem)
            
            elif tag_name in ['span', 'strong', 'b', 'em', 'i']:
                json_elem = self._parse_text(child)
                if json_elem:
                    children.append(json_elem)
        except Exception as e:
            # טיפול בשגיאות - דילוג על אלמנטים בעייתיים
            print(f"⚠️  שגיאה בעיבוד אלמנט: {e}")
            pass
        
        return children
    
    def _parse_div(self, element) -> Optional[Dict]:
        """ממיר div ל-JSON"""
        if not element or not isinstance(element, Tag):
            return None
        
        classes = element.get('class', [])
        if isinstance(classes, str):
            classes = classes.split()
        
        # בדיקה אם זה column או row
        is_column = 'flex-col' in classes or 'space-y' in classes
        is_row = 'flex' in classes and 'flex-col' not in classes
        is_grid = 'grid' in classes
        
        # חילוץ ילדים
        children = self._convert_element_to_json(element)
        
        if is_row:
            return {
                "type": "row",
                "children": children
            }
        elif is_grid:
            # Grid - ממיר ל-column עם children
            return {
                "type": "column",
                "children": children
            }
        elif children:
            return {
                "type": "column",
                "children": children
            }
        
        return None
    
    def _parse_heading(self, element) -> Optional[Dict]:
        """ממיר heading ל-text widget"""
        if not element or not isinstance(element, Tag) or not element.name:
            return None
        
        text = element.get_text(strip=True)
        if not text:
            return None
        
        tag = element.name.lower()
        # מיפוי גודלי גופן
        font_sizes = {
            'h1': 32,
            'h2': 28,
            'h3': 24,
            'h4': 20,
            'h5': 18,
            'h6': 16
        }
        
        classes = element.get('class', [])
        if isinstance(classes, str):
            classes = classes.split()
        
        is_bold = 'font-bold' in classes or 'bold' in classes
        
        return {
            "type": "text",
            "value": text,
            "fontSize": font_sizes.get(tag, 20),
            "fontWeight": "bold" if is_bold else "normal"
        }
    
    def _parse_text(self, element) -> Optional[Dict]:
        """ממיר טקסט ל-text widget"""
        if not element or not isinstance(element, Tag):
            return None
        
        text = element.get_text(strip=True)
        if not text:
            return None
        
        classes = element.get('class', [])
        if isinstance(classes, str):
            classes = classes.split()
        
        # חילוץ צבע
        color = self._extract_color_from_classes(classes)
        
        # חילוץ גודל גופן
        fontSize = self._extract_font_size_from_classes(classes)
        
        # חילוץ משקל גופן
        fontWeight = "normal"
        if 'font-bold' in classes or 'bold' in classes:
            fontWeight = "bold"
        elif 'font-light' in classes:
            fontWeight = "light"
        
        return {
            "type": "text",
            "value": text,
            "fontSize": fontSize,
            "fontWeight": fontWeight,
            "color": color
        }
    
    def _parse_button(self, element) -> Optional[Dict]:
        """ממיר button ל-button widget"""
        if not element or not isinstance(element, Tag):
            return None
        
        text = element.get_text(strip=True)
        if not text:
            return None
        
        classes = element.get('class', [])
        if isinstance(classes, str):
            classes = classes.split()
        
        # חילוץ action
        action_id = None
        onclick = element.get('@click') or element.get('onclick', '')
        if onclick and isinstance(onclick, str):
            # ניקוי ה-action
            action_name = onclick.strip()
            action_name = re.sub(r'activeTab\s*=\s*[\'"](\w+)[\'"]', r'goTo\1', action_name)
            action_name = re.sub(r'(\w+)\(', r'\1', action_name)
            action_name = action_name.replace('()', '').strip()
            
            if action_name:
                action_id = self._camel_to_snake(action_name)
                
                # יצירת action אם לא קיים
                if action_id not in self.actions:
                    if 'goTo' in action_id or 'navigate' in action_id:
                        route = action_id.replace('go_to_', '').replace('goTo', '')
                        self.actions[action_id] = {
                            "type": "navigation",
                            "route": route
                        }
                    else:
                        self.actions[action_id] = {
                            "type": "api",
                            "method": "POST",
                            "endpoint": f"/api/{action_id}"
                        }
        
        # חילוץ צבעים
        bg_color = None
        text_color = None
        
        if 'btn-primary' in classes:
            bg_color = self.styles.get('primaryColor', '#4f46e5')
        elif 'btn-secondary' in classes:
            bg_color = self.styles.get('secondaryColor', '#7c3aed')
        else:
            bg_color = self._extract_bg_color_from_classes(classes)
        
        return {
            "type": "button",
            "text": text,
            "action": action_id,
            "backgroundColor": bg_color,
            "textColor": text_color
        }
    
    def _parse_input(self, element) -> Optional[Dict]:
        """ממיר input ל-form field"""
        if not element or not isinstance(element, Tag):
            return None
        
        input_type = element.get('type', 'text')
        placeholder = element.get('placeholder', '')
        label_text = placeholder or 'שדה'
        
        # חיפוש label קשור
        label_id = element.get('id')
        if label_id:
            label = self.soup.find('label', {'for': label_id})
            if label:
                label_text = label.get_text(strip=True)
        
        if input_type == 'checkbox':
            return {
                "type": "text",
                "value": f"☐ {label_text}",
                "fontSize": 14
            }
        else:
            return {
                "type": "text",
                "value": f"{label_text}: {placeholder}",
                "fontSize": 14,
                "color": "#6b7280"
            }
    
    def _parse_label(self, element) -> Optional[Dict]:
        """ממיר label ל-text widget"""
        if not element or not isinstance(element, Tag):
            return None
        
        text = element.get_text(strip=True)
        if not text:
            return None
        
        return {
            "type": "text",
            "value": text,
            "fontSize": 16,
            "fontWeight": "bold"
        }
    
    def _parse_image(self, element) -> Optional[Dict]:
        """ממיר img ל-image widget"""
        if not element or not isinstance(element, Tag):
            return None
        
        src = element.get('src', '')
        if not src:
            return None
        
        # חילוץ גובה ורוחב
        height = element.get('height')
        width = element.get('width')
        
        # המרה ל-numbers
        if height:
            try:
                height = int(height)
            except:
                height = None
        
        if width:
            try:
                width = int(width)
            except:
                width = None
        
        # העתקת תמונה ל-assets אם צריך
        asset_path = self._copy_image_to_assets(src)
        
        return {
            "type": "image",
            "asset": asset_path,
            "height": height,
            "width": width
        }
    
    def _parse_form(self, element) -> Optional[Dict]:
        """ממיר form ל-form widget"""
        if not element or not isinstance(element, Tag):
            return None
        
        fields = []
        actions = []
        
        # חילוץ שדות
        inputs = element.find_all('input')
        for inp in inputs:
            field = self._parse_input(inp)
            if field:
                fields.append(field)
        
        # חילוץ כפתורים
        buttons = element.find_all('button')
        for btn in buttons:
            button_json = self._parse_button(btn)
            if button_json:
                actions.append(button_json)
        
        return {
            "type": "form",
            "fields": fields,
            "actions": actions
        }
    
    def _extract_color_from_classes(self, classes: List[str]) -> Optional[str]:
        """חילוץ צבע מ-Tailwind classes"""
        color_map = {
            'text-white': '#ffffff',
            'text-black': '#000000',
            'text-gray-500': '#6b7280',
            'text-gray-600': '#4b5563',
            'text-gray-700': '#374151',
            'text-indigo-600': '#4f46e5',
            'text-purple-600': '#7c3aed',
            'text-green-600': '#10b981',
            'text-red-600': '#dc2626',
            'text-blue-600': '#2563eb',
        }
        
        for cls in classes:
            if cls in color_map:
                return color_map[cls]
        
        return None
    
    def _extract_bg_color_from_classes(self, classes: List[str]) -> Optional[str]:
        """חילוץ צבע רקע מ-Tailwind classes"""
        color_map = {
            'bg-indigo-600': '#4f46e5',
            'bg-purple-600': '#7c3aed',
            'bg-gray-100': '#f3f4f6',
            'bg-white': '#ffffff',
        }
        
        for cls in classes:
            if cls in color_map:
                return color_map[cls]
        
        return None
    
    def _extract_font_size_from_classes(self, classes: List[str]) -> float:
        """חילוץ גודל גופן מ-Tailwind classes"""
        size_map = {
            'text-xs': 12,
            'text-sm': 14,
            'text-base': 16,
            'text-lg': 18,
            'text-xl': 20,
            'text-2xl': 24,
            'text-3xl': 30,
        }
        
        for cls in classes:
            if cls in size_map:
                return size_map[cls]
        
        return 16.0
    
    def _copy_image_to_assets(self, src: str) -> str:
        """מעתיק תמונה ל-assets ומחזיר נתיב יחסי"""
        if not src or src.startswith('http'):
            return src
        
        # ניקוי נתיב
        src_path = Path(src)
        if src_path.exists():
            # העתקה
            dest_path = self.assets_dir / src_path.name
            import shutil
            shutil.copy2(src_path, dest_path)
            return f"assets/{src_path.name}"
        
        return src
    
    def _camel_to_snake(self, text: str) -> str:
        """ממיר camelCase ל-snake_case"""
        if not text or not isinstance(text, str):
            return ""
        # הוספת _ לפני אותיות גדולות
        text = re.sub(r'(?<!^)(?=[A-Z])', '_', text)
        return text.lower()
    
    def _create_app_json(self):
        """יוצר app.json"""
        app_json = {
            "appId": self.app_id,
            "version": "1.0.0",
            "initialRoute": "home" if "home" in self.routes else list(self.routes.keys())[0],
            "rtl": True  # נניח RTL אם יש עברית
        }
        
        with open(self.app_dir / "app.json", 'w', encoding='utf-8') as f:
            json.dump(app_json, f, ensure_ascii=False, indent=2)
    
    def _create_routes_json(self):
        """יוצר routes.json"""
        with open(self.app_dir / "routes.json", 'w', encoding='utf-8') as f:
            json.dump(self.routes, f, ensure_ascii=False, indent=2)
    
    def _create_styles_json(self):
        """יוצר styles.json"""
        with open(self.app_dir / "styles.json", 'w', encoding='utf-8') as f:
            json.dump(self.styles, f, ensure_ascii=False, indent=2)
    
    def _create_actions_json(self):
        """יוצר actions.json"""
        if not self.actions:
            # יצירת actions בסיסיים
            self.actions = {
                "goToHome": {
                    "type": "navigation",
                    "route": "home"
                }
            }
        
        with open(self.app_dir / "actions.json", 'w', encoding='utf-8') as f:
            json.dump(self.actions, f, ensure_ascii=False, indent=2)
    
    def _create_zip(self, output_zip_path: Path):
        """יוצר קובץ ZIP"""
        print(f"📦 יוצר קובץ ZIP: {output_zip_path.name}...")
        
        with zipfile.ZipFile(output_zip_path, 'w', zipfile.ZIP_DEFLATED) as zipf:
            # הוספת קבצי הגדרה
            for file in ['app.json', 'routes.json', 'styles.json', 'actions.json']:
                file_path = self.app_dir / file
                if file_path.exists():
                    zipf.write(file_path, file)
            
            # הוספת מסכים
            for screen_id, screen_json in self.screens.items():
                screen_file = self.screens_dir / f"{screen_id}.json"
                with open(screen_file, 'w', encoding='utf-8') as f:
                    json.dump(screen_json, f, ensure_ascii=False, indent=2)
                zipf.write(screen_file, f"screens/{screen_id}.json")
            
            # הוספת assets
            if self.assets_dir.exists():
                for asset_file in self.assets_dir.rglob('*'):
                    if asset_file.is_file():
                        zipf.write(asset_file, f"assets/{asset_file.name}")


def convert_directory(input_dir: str, output_dir: str = None):
    """ממיר תיקייה שלמה עם קבצי HTML"""
    input_path = Path(input_dir)
    
    if not input_path.exists():
        print(f"❌ שגיאה: התיקייה {input_dir} לא קיימת")
        return
    
    # חיפוש קבצי HTML
    html_files = list(input_path.glob('*.html')) + list(input_path.glob('*.htm'))
    
    if not html_files:
        print(f"❌ לא נמצאו קבצי HTML בתיקייה {input_dir}")
        return
    
    print(f"\n📁 נמצאו {len(html_files)} קבצי HTML:")
    for i, html_file in enumerate(html_files, 1):
        print(f"  {i}. {html_file.name}")
    
    # שאילת המשתמש על תיקיית פלט
    if not output_dir:
        print("\n" + "="*60)
        print("📁 בחירת תיקיית פלט")
        print("="*60)
        default_dir = Path.cwd() / "converted_apps"
        print(f"\nתיקייה ברירת מחדל: {default_dir}")
        user_input = input("הזן נתיב לתיקיית פלט (Enter לברירת מחדל): ").strip()
        
        if user_input:
            output_path = Path(user_input)
        else:
            output_path = default_dir
    else:
        output_path = Path(output_dir)
    
    output_path.mkdir(parents=True, exist_ok=True)
    
    print(f"\n✅ תיקיית פלט: {output_path}")
    print(f"🔄 מתחיל המרה של {len(html_files)} קבצים...\n")
    
    # המרה של כל קובץ
    converted_count = 0
    for html_file in html_files:
        try:
            converter = HTMLToZipConverter(
                html_file=str(html_file),
                output_dir=str(output_path),
                app_id=html_file.stem
            )
            converter.convert()
            converted_count += 1
        except Exception as e:
            print(f"❌ שגיאה בהמרת {html_file.name}: {e}")
    
    print(f"\n{'='*60}")
    print(f"✅ הושלם! הומרו {converted_count}/{len(html_files)} קבצים")
    print(f"📁 תיקיית פלט: {output_path}")
    print(f"📦 קבצי ZIP נוצרו בתיקייה: {output_path}")
    print(f"{'='*60}\n")


def main():
    """פונקציה ראשית"""
    import argparse
    
    parser = argparse.ArgumentParser(
        description='ממיר HTML לקובץ ZIP בפורמט Dynamic UI Runtime Engine',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
דוגמאות שימוש:
  # המרת תיקייה שלמה (ישאל איפה ליצור את התיקייה החדשה)
  python html_to_zip_converter.py ./html_files
  
  # המרת תיקייה עם תיקיית פלט מוגדרת
  python html_to_zip_converter.py ./html_files -o ./output
  
  # המרת קובץ יחיד
  python html_to_zip_converter.py index.html -o ./output
        """
    )
    parser.add_argument('input', help='נתיב לקובץ HTML או תיקייה עם קבצי HTML')
    parser.add_argument('-o', '--output', help='נתיב לתיקיית פלט (אם לא מוגדר, ישאל את המשתמש)')
    parser.add_argument('-a', '--app-id', help='מזהה האפליקציה (רק לקובץ יחיד)')
    
    args = parser.parse_args()
    
    input_path = Path(args.input)
    
    if input_path.is_file():
        # קובץ יחיד
        converter = HTMLToZipConverter(
            html_file=str(input_path),
            output_dir=args.output,
            app_id=args.app_id or input_path.stem
        )
        converter.convert()
    elif input_path.is_dir():
        # תיקייה
        convert_directory(str(input_path), args.output)
    else:
        print(f"❌ שגיאה: {args.input} אינו קובץ או תיקייה תקינים")


if __name__ == '__main__':
    main()

