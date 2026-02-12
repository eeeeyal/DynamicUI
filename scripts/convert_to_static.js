const fs = require('fs');

// Read the original HTML file
let html = fs.readFileSync('index.html', 'utf8');

// Remove v-cloak attribute
html = html.replace(/\s+v-cloak/g, '');

// Remove Vue script tags
html = html.replace(/<script[^>]*src="https:\/\/unpkg.com\/vue[^"]*"[^>]*><\/script>/g, '');
html = html.replace(/<script[^>]*src="https:\/\/cdn.tailwindcss.com[^"]*"[^>]*><\/script>/g, '');

// Remove v-cloak style
html = html.replace(/\[v-cloak\]\s*\{[^}]*\}/g, '');

// Handle v-show directives - show first tab (settings), hide others
// Use a more careful replacement that preserves the content
html = html.replace(/v-show="activeTab\s*===\s*['"]settings['"]"\s*/g, '');
html = html.replace(/(<div[^>]*)\s+v-show="activeTab\s*===\s*['"]tests['"]"\s*([^>]*>)/g, '$1 style="display: none;" $2');
html = html.replace(/(<div[^>]*)\s+v-show="activeTab\s*===\s*['"]transactions['"]"\s*([^>]*>)/g, '$1 style="display: none;" $2');
html = html.replace(/(<div[^>]*)\s+v-show="activeTab\s*===\s*['"]advanced['"]"\s*([^>]*>)/g, '$1 style="display: none;" $2');
html = html.replace(/(<div[^>]*)\s+v-show="activeTab\s*===\s*['"]files['"]"\s*([^>]*>)/g, '$1 style="display: none;" $2');
html = html.replace(/(<div[^>]*)\s+v-show="activeTab\s*===\s*['"]ui['"]"\s*([^>]*>)/g, '$1 style="display: none;" $2');
html = html.replace(/(<div[^>]*)\s+v-show="activeTab\s*===\s*['"]history['"]"\s*([^>]*>)/g, '$1 style="display: none;" $2');

// Remove v-model attributes and add value/checked attributes
html = html.replace(/v-model="config\.brokerUrl"/g, 'value="https://212.235.22.50:5000"');
html = html.replace(/v-model="config\.terminalId"/g, 'value="0880264"');
html = html.replace(/v-model="config\.terminalNo"/g, 'value="001"');
html = html.replace(/v-model="config\.debug"/g, 'checked');
html = html.replace(/v-model="config\.mockMode"/g, '');
html = html.replace(/v-model\.number="amount"/g, 'value="10000"');
html = html.replace(/v-model\.number="([^"]+)"/g, 'value="0"');
html = html.replace(/v-model="([^"]+)"/g, 'value=""');

// Remove v-if directives
html = html.replace(/v-if="filteredLogs\.length\s*===\s*0"/g, '');
html = html.replace(/v-if="transactionHistory\.length\s*===\s*0"/g, '');
html = html.replace(/v-if="isConnected"/g, 'style="display: none;"');
html = html.replace(/v-if="([^"]+)"/g, 'style="display: none;"');

// Remove v-else
html = html.replace(/\s+v-else/g, '');

// Remove v-for directives
html = html.replace(/v-for="\(log,\s*index\)\s+in\s+filteredLogs"\s+:key="index"/g, '');
html = html.replace(/v-for="\(trans,\s*index\)\s+in\s+transactionHistory"\s+:key="index"/g, 'style="display: none;"');
html = html.replace(/v-for="([^"]+)"/g, '');

// Remove @click handlers
html = html.replace(/\s+@click="[^"]*"/g, '');

// Replace :class bindings with static classes
html = html.replace(/:class="activeTab\s*===\s*['"]settings['"]\s*\?\s*['"]tab-active['"]\s*:\s*['"]tab-inactive['"]"/g, 'class="tab-button tab-active"');
html = html.replace(/:class="activeTab\s*===\s*['"]tests['"]\s*\?\s*['"]tab-active['"]\s*:\s*['"]tab-inactive['"]"/g, 'class="tab-button tab-inactive"');
html = html.replace(/:class="activeTab\s*===\s*['"]transactions['"]\s*\?\s*['"]tab-active['"]\s*:\s*['"]tab-inactive['"]"/g, 'class="tab-button tab-inactive"');
html = html.replace(/:class="activeTab\s*===\s*['"]advanced['"]\s*\?\s*['"]tab-active['"]\s*:\s*['"]tab-inactive['"]"/g, 'class="tab-button tab-inactive"');
html = html.replace(/:class="activeTab\s*===\s*['"]files['"]\s*\?\s*['"]tab-active['"]\s*:\s*['"]tab-inactive['"]"/g, 'class="tab-button tab-inactive"');
html = html.replace(/:class="activeTab\s*===\s*['"]ui['"]\s*\?\s*['"]tab-active['"]\s*:\s*['"]tab-inactive['"]"/g, 'class="tab-button tab-inactive"');
html = html.replace(/:class="activeTab\s*===\s*['"]history['"]\s*\?\s*['"]tab-active['"]\s*:\s*['"]tab-inactive['"]"/g, 'class="tab-button tab-inactive"');
html = html.replace(/:class="xmlView\s*\?\s*['"]bg-indigo-100\s+text-indigo-700['"]\s*:\s*['"]bg-gray-100\s+text-gray-600['"]"/g, 'class="text-xs px-3 py-1 bg-gray-100 text-gray-600 rounded transition-colors"');
html = html.replace(/:class="statusClass"/g, 'class="text-red-600"');
html = html.replace(/:class="isConnected\s*\?\s*['"]bg-green-500['"]\s*:\s*['"]bg-red-500['"]"/g, 'class="relative inline-flex rounded-full h-2.5 w-2.5 bg-red-500"');
html = html.replace(/:class="getLogClass\(log\.type\)"/g, 'class="mb-1 leading-relaxed whitespace-pre-wrap break-words text-green-500"');
html = html.replace(/:class="([^"]+)"/g, '');

// Replace {{ }} interpolations with static values
html = html.replace(/\{\{\s*\(amount\s*\/\s*100\)\.toFixed\(2\)\s*\}\}/g, '100.00');
html = html.replace(/\{\{\s*xmlView\s*\?\s*['"]📄\s+XML['"]\s*:\s*['"]📊\s+JSON['"]\s*\}\}/g, '📊 JSON');
html = html.replace(/\{\{\s*statusText\s*\}\}/g, 'לא מחובר');
html = html.replace(/\{\{\s*config\.brokerUrl\s*\}\}/g, 'https://212.235.22.50:5000');
html = html.replace(/\{\{\s*stats\.totalRequests\s*\}\}/g, '0');
html = html.replace(/\{\{\s*stats\.successCount\s*\}\}/g, '0');
html = html.replace(/\{\{\s*stats\.errorCount\s*\}\}/g, '0');
html = html.replace(/\{\{\s*log\.time\s*\}\}/g, '10:39:54');
html = html.replace(/\{\{\s*log\.message\s*\}\}/g, 'CASPIT SDK נטען בהצלחה');
html = html.replace(/\{\{\s*\(trans\.amount\s*\/\s*100\)\.toFixed\(2\)\s*\}\}/g, '0.00');
html = html.replace(/\{\{\s*trans\.uid\s*\}\}/g, '');
html = html.replace(/\{\{\s*trans\.timestamp\s*\}\}/g, '');
html = html.replace(/\{\{\s*trans\.status\s*===\s*['"]success['"]\s*\?\s*['"]✅\s+אושר['"]\s*:\s*['"]❌\s+נדחה['"]\s*\}\}/g, '✅ אושר');
html = html.replace(/\{\{\s*trans\.authNo\s*\}\}/g, '');
html = html.replace(/\{\{\s*trans\.cardName\s*\}\}/g, '');
html = html.replace(/\{\{\s*trans\.pan\s*\}\}/g, '');
html = html.replace(/\{\{\s*advancedTran\.showFuel\s*\?\s*['"]▼['"]\s*:\s*['"]▶['"]\s*\}\}/g, '▶');
html = html.replace(/\{\{\s*([^}]+)\s*\}\}/g, '');

// Remove :disabled bindings
html = html.replace(/\s+:disabled="[^"]*"/g, '');

// Remove :value bindings
html = html.replace(/\s+:value="[^"]*"/g, '');

// Remove :key bindings
html = html.replace(/\s+:key="[^"]*"/g, '');

// Remove all script tags (Vue app code) - but only those that are not CDN links (already removed)
// Remove script tags that contain Vue app code (between <script> and </script>)
html = html.replace(/<script[^>]*>[\s\S]*?<\/script>/g, function(match) {
    // Keep CDN links (already removed earlier, but just in case)
    if (match.includes('cdn.tailwindcss.com') || match.includes('unpkg.com/vue')) {
        return '';
    }
    // Remove Vue app code
    return '';
});

// Write the static version
fs.writeFileSync('index_static.html', html, 'utf8');

console.log('Conversion complete! Created index_static.html');

