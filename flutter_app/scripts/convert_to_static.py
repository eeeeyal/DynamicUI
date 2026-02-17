#!/usr/bin/env python3
"""
Convert index.html to static version by removing Vue.js directives
and making all tabs visible (but only first tab shown by default)
"""

import re

def convert_to_static(html_content):
    """Convert Vue.js HTML to static HTML"""
    
    # Remove v-cloak attribute
    html_content = re.sub(r'\s+v-cloak', '', html_content)
    
    # Remove Vue script tags
    html_content = re.sub(r'<script[^>]*>.*?</script>', '', html_content, flags=re.DOTALL)
    
    # Remove Vue CDN links
    html_content = re.sub(r'<script[^>]*src="https://unpkg.com/vue[^"]*"[^>]*></script>', '', html_content)
    
    # Remove v-cloak style
    html_content = re.sub(r'\[v-cloak\]\s*\{[^}]*\}', '', html_content)
    
    # Handle v-show directives - show first tab, hide others
    tab_contents = []
    tab_pattern = r'<div\s+v-show="activeTab\s*===\s*[\'"](\w+)[\'"]"\s*([^>]*)>'
    
    def replace_v_show(match):
        tab_name = match.group(1)
        attrs = match.group(2)
        
        # First tab (settings) should be visible, others hidden
        if tab_name == 'settings':
            return f'<div {attrs}>'
        else:
            # Add display: none for other tabs
            if 'style=' in attrs:
                # Append to existing style
                attrs = re.sub(r'style="([^"]*)"', r'style="\1; display: none;"', attrs)
            else:
                attrs = f'style="display: none;" {attrs}'
            return f'<div {attrs}>'
    
    html_content = re.sub(tab_pattern, replace_v_show, html_content)
    
    # Remove v-model attributes and add value/checked attributes
    def replace_v_model(match):
        element = match.group(0)
        v_model = match.group(1)
        
        # For inputs, add value attribute
        if '<input' in element:
            if 'type="checkbox"' in element:
                # For checkboxes, add checked if it's likely checked
                if 'debug' in v_model.lower() or 'mock' in v_model.lower():
                    element = element.replace('v-model=', 'checked ')
                else:
                    element = element.replace('v-model=', '')
            elif 'type="number"' in element:
                # For number inputs, add default value
                if 'amount' in v_model.lower():
                    element = element.replace('v-model.number=', 'value="10000" ')
                elif 'timeout' in v_model.lower():
                    element = element.replace('v-model.number=', 'value="10" ')
                else:
                    element = element.replace('v-model.number=', 'value="0" ')
            else:
                # For text inputs, add default value
                if 'brokerUrl' in v_model:
                    element = element.replace('v-model=', 'value="https://212.235.22.50:5000" ')
                elif 'terminalId' in v_model:
                    element = element.replace('v-model=', 'value="0880264" ')
                elif 'terminalNo' in v_model:
                    element = element.replace('v-model=', 'value="001" ')
                else:
                    element = element.replace('v-model=', 'value="" ')
        elif '<select' in element:
            element = element.replace('v-model.number=', 'value="1" ')
            element = element.replace('v-model=', 'value="1" ')
        elif '<textarea' in element:
            element = element.replace('v-model=', '')
        
        return element
    
    html_content = re.sub(r'v-model(?:\.number)?="([^"]+)"', replace_v_model, html_content)
    
    # Remove v-if directives and handle conditions
    def replace_v_if(match):
        condition = match.group(1)
        element = match.group(0)
        
        # For most v-if conditions, hide the element
        # But we can show some default states
        if 'filteredLogs.length === 0' in condition:
            # Show empty state
            return element.replace('v-if="filteredLogs.length === 0"', '')
        elif 'transactionHistory.length === 0' in condition:
            # Show empty history
            return element.replace('v-if="transactionHistory.length === 0"', '')
        elif 'isConnected' in condition:
            # Hide connection status elements
            return element.replace('v-if="isConnected"', 'style="display: none;"')
        else:
            # Hide other conditional elements
            return element.replace('v-if="[^"]*"', 'style="display: none;"')
    
    html_content = re.sub(r'v-if="([^"]+)"', replace_v_if, html_content)
    
    # Remove v-else
    html_content = re.sub(r'\s+v-else', '', html_content)
    
    # Remove v-for directives
    def replace_v_for(match):
        element = match.group(0)
        # For v-for, we'll show a single example or hide
        if 'filteredLogs' in element:
            # Show one example log entry
            return element.replace('v-for="(log, index) in filteredLogs" :key="index"', '')
        elif 'transactionHistory' in element:
            # Hide history entries
            return element.replace('v-for="(trans, index) in transactionHistory" :key="index"', 'style="display: none;"')
        else:
            return element.replace('v-for="[^"]*"', '')
    
    html_content = re.sub(r'v-for="([^"]+)"', replace_v_for, html_content)
    
    # Remove @click handlers
    html_content = re.sub(r'\s+@click="[^"]*"', '', html_content)
    
    # Remove :class bindings and replace with static classes
    def replace_class_binding(match):
        binding = match.group(1)
        element = match.group(0)
        
        # Handle common class bindings
        if 'activeTab ===' in binding:
            # Tab buttons - first is active
            if "'settings'" in binding or '"settings"' in binding:
                return element.replace(':class="[^"]*"', 'class="tab-button tab-active"')
            else:
                return element.replace(':class="[^"]*"', 'class="tab-button tab-inactive"')
        elif 'xmlView' in binding:
            # XML view button - default to JSON view
            return element.replace(':class="[^"]*"', 'class="text-xs px-3 py-1 bg-gray-100 text-gray-600 rounded transition-colors"')
        elif 'statusClass' in binding:
            # Status - default to disconnected
            return element.replace(':class="[^"]*"', 'class="text-red-600"')
        elif 'isConnected' in binding:
            # Connection indicator - default to disconnected
            return element.replace(':class="[^"]*"', 'class="relative inline-flex rounded-full h-2.5 w-2.5 bg-red-500"')
        elif 'getLogClass' in binding:
            # Log entry - default to success
            return element.replace(':class="[^"]*"', 'class="mb-1 leading-relaxed whitespace-pre-wrap break-words text-green-500"')
        else:
            # Remove binding, keep static classes
            return element.replace(':class="[^"]*"', '')
    
    html_content = re.sub(r':class="([^"]+)"', replace_class_binding, html_content)
    
    # Remove {{ }} interpolations and replace with static values
    def replace_interpolation(match):
        expr = match.group(1)
        
        # Handle common interpolations
        if 'amount / 100' in expr:
            return '100.00'
        elif 'xmlView' in expr:
            return 'JSON'
        elif 'statusText' in expr:
            return 'לא מחובר'
        elif 'config.brokerUrl' in expr:
            return 'https://212.235.22.50:5000'
        elif 'stats.totalRequests' in expr:
            return '0'
        elif 'stats.successCount' in expr:
            return '0'
        elif 'stats.errorCount' in expr:
            return '0'
        elif 'log.time' in expr:
            return '10:39:54'
        elif 'log.message' in expr:
            return 'CASPIT SDK נטען בהצלחה'
        elif 'trans.amount' in expr:
            return '0.00'
        elif 'trans.uid' in expr:
            return ''
        elif 'trans.timestamp' in expr:
            return ''
        elif 'trans.status' in expr:
            return 'success'
        elif 'trans.authNo' in expr:
            return ''
        elif 'trans.cardName' in expr:
            return ''
        elif 'trans.pan' in expr:
            return ''
        elif 'filesPagination.statisCurrentRecord' in expr:
            return '0'
        elif 'filesPagination.statisTotalRecords' in expr:
            return '0'
        elif 'filesPagination.tranCurrentRecord' in expr:
            return '0'
        elif 'filesPagination.tranTotalRecords' in expr:
            return '0'
        elif 'advancedTran.showFuel' in expr:
            return '▶'
        else:
            return ''
    
    html_content = re.sub(r'\{\{\s*([^}]+)\s*\}\}', replace_interpolation, html_content)
    
    # Remove :disabled bindings
    html_content = re.sub(r'\s+:disabled="[^"]*"', '', html_content)
    
    # Remove :value bindings
    html_content = re.sub(r'\s+:value="[^"]*"', '', html_content)
    
    # Remove :key bindings
    html_content = re.sub(r'\s+:key="[^"]*"', '', html_content)
    
    return html_content

def main():
    # Read the original HTML file
    with open('index.html', 'r', encoding='utf-8') as f:
        html_content = f.read()
    
    # Convert to static
    static_html = convert_to_static(html_content)
    
    # Write the static version
    with open('index_static.html', 'w', encoding='utf-8') as f:
        f.write(static_html)
    
    print("Conversion complete! Created index_static.html")

if __name__ == '__main__':
    main()

