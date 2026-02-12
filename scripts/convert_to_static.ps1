# Convert index.html to static version
$html = Get-Content -Path "index.html" -Raw -Encoding UTF8

# Remove v-cloak attribute
$html = $html -replace '\s+v-cloak', ''

# Remove Vue script tags (keep content, remove script tags)
$html = $html -replace '<script[^>]*>.*?</script>', '' -replace '(?s)'

# Remove Vue CDN links
$html = $html -replace '<script[^>]*src="https://unpkg.com/vue[^"]*"[^>]*></script>', ''

# Remove v-cloak style
$html = $html -replace '\[v-cloak\]\s*\{[^}]*\}', ''

# Handle v-show directives - show first tab (settings), hide others
$html = $html -replace 'v-show="activeTab\s*===\s*[''"]settings[''"]"\s*', ''
$html = $html -replace 'v-show="activeTab\s*===\s*[''"]tests[''"]"\s*', 'style="display: none;" '
$html = $html -replace 'v-show="activeTab\s*===\s*[''"]transactions[''"]"\s*', 'style="display: none;" '
$html = $html -replace 'v-show="activeTab\s*===\s*[''"]advanced[''"]"\s*', 'style="display: none;" '
$html = $html -replace 'v-show="activeTab\s*===\s*[''"]files[''"]"\s*', 'style="display: none;" '
$html = $html -replace 'v-show="activeTab\s*===\s*[''"]ui[''"]"\s*', 'style="display: none;" '
$html = $html -replace 'v-show="activeTab\s*===\s*[''"]history[''"]"\s*', 'style="display: none;" '

# Remove v-model attributes and add value/checked attributes
$html = $html -replace 'v-model="config\.brokerUrl"', 'value="https://212.235.22.50:5000"'
$html = $html -replace 'v-model="config\.terminalId"', 'value="0880264"'
$html = $html -replace 'v-model="config\.terminalNo"', 'value="001"'
$html = $html -replace 'v-model="config\.debug"', 'checked'
$html = $html -replace 'v-model="config\.mockMode"', ''
$html = $html -replace 'v-model\.number="amount"', 'value="10000"'
$html = $html -replace 'v-model\.number="([^"]+)"', 'value="0"'
$html = $html -replace 'v-model="([^"]+)"', 'value=""'

# Remove v-if directives
$html = $html -replace 'v-if="filteredLogs\.length\s*===\s*0"', ''
$html = $html -replace 'v-if="transactionHistory\.length\s*===\s*0"', ''
$html = $html -replace 'v-if="isConnected"', 'style="display: none;"'
$html = $html -replace 'v-if="([^"]+)"', 'style="display: none;"'

# Remove v-else
$html = $html -replace '\s+v-else', ''

# Remove v-for directives
$html = $html -replace 'v-for="\(log,\s*index\)\s+in\s+filteredLogs"\s+:key="index"', ''
$html = $html -replace 'v-for="\(trans,\s*index\)\s+in\s+transactionHistory"\s+:key="index"', 'style="display: none;"'
$html = $html -replace 'v-for="([^"]+)"', ''

# Remove @click handlers
$html = $html -replace '\s+@click="[^"]*"', ''

# Replace :class bindings with static classes
$html = $html -replace ':class="activeTab\s*===\s*[''"]settings[''"]\s*\?\s*[''"]tab-active[''"]\s*:\s*[''"]tab-inactive[''"]"', 'class="tab-button tab-active"'
$html = $html -replace ':class="activeTab\s*===\s*[''"]tests[''"]\s*\?\s*[''"]tab-active[''"]\s*:\s*[''"]tab-inactive[''"]"', 'class="tab-button tab-inactive"'
$html = $html -replace ':class="activeTab\s*===\s*[''"]transactions[''"]\s*\?\s*[''"]tab-active[''"]\s*:\s*[''"]tab-inactive[''"]"', 'class="tab-button tab-inactive"'
$html = $html -replace ':class="activeTab\s*===\s*[''"]advanced[''"]\s*\?\s*[''"]tab-active[''"]\s*:\s*[''"]tab-inactive[''"]"', 'class="tab-button tab-inactive"'
$html = $html -replace ':class="activeTab\s*===\s*[''"]files[''"]\s*\?\s*[''"]tab-active[''"]\s*:\s*[''"]tab-inactive[''"]"', 'class="tab-button tab-inactive"'
$html = $html -replace ':class="activeTab\s*===\s*[''"]ui[''"]\s*\?\s*[''"]tab-active[''"]\s*:\s*[''"]tab-inactive[''"]"', 'class="tab-button tab-inactive"'
$html = $html -replace ':class="activeTab\s*===\s*[''"]history[''"]\s*\?\s*[''"]tab-active[''"]\s*:\s*[''"]tab-inactive[''"]"', 'class="tab-button tab-inactive"'
$html = $html -replace ':class="xmlView\s*\?\s*[''"]bg-indigo-100\s+text-indigo-700[''"]\s*:\s*[''"]bg-gray-100\s+text-gray-600[''"]"', 'class="text-xs px-3 py-1 bg-gray-100 text-gray-600 rounded transition-colors"'
$html = $html -replace ':class="statusClass"', 'class="text-red-600"'
$html = $html -replace ':class="isConnected\s*\?\s*[''"]bg-green-500[''"]\s*:\s*[''"]bg-red-500[''"]"', 'class="relative inline-flex rounded-full h-2.5 w-2.5 bg-red-500"'
$html = $html -replace ':class="getLogClass\(log\.type\)"', 'class="mb-1 leading-relaxed whitespace-pre-wrap break-words text-green-500"'
$html = $html -replace ':class="([^"]+)"', ''

# Replace {{ }} interpolations with static values
$html = $html -replace '\{\{\s*\(amount\s*/\s*100\)\.toFixed\(2\)\s*\}\}', '100.00'
$html = $html -replace '\{\{\s*xmlView\s*\?\s*[''"]📄\s+XML[''"]\s*:\s*[''"]📊\s+JSON[''"]\s*\}\}', '📊 JSON'
$html = $html -replace '\{\{\s*statusText\s*\}\}', 'לא מחובר'
$html = $html -replace '\{\{\s*config\.brokerUrl\s*\}\}', 'https://212.235.22.50:5000'
$html = $html -replace '\{\{\s*stats\.totalRequests\s*\}\}', '0'
$html = $html -replace '\{\{\s*stats\.successCount\s*\}\}', '0'
$html = $html -replace '\{\{\s*stats\.errorCount\s*\}\}', '0'
$html = $html -replace '\{\{\s*log\.time\s*\}\}', '10:39:54'
$html = $html -replace '\{\{\s*log\.message\s*\}\}', 'CASPIT SDK נטען בהצלחה'
$html = $html -replace '\{\{\s*\(trans\.amount\s*/\s*100\)\.toFixed\(2\)\s*\}\}', '0.00'
$html = $html -replace '\{\{\s*trans\.uid\s*\}\}', ''
$html = $html -replace '\{\{\s*trans\.timestamp\s*\}\}', ''
$html = $html -replace '\{\{\s*trans\.status\s*===\s*[''"]success[''"]\s*\?\s*[''"]✅\s+אושר[''"]\s*:\s*[''"]❌\s+נדחה[''"]\s*\}\}', '✅ אושר'
$html = $html -replace '\{\{\s*trans\.authNo\s*\}\}', ''
$html = $html -replace '\{\{\s*trans\.cardName\s*\}\}', ''
$html = $html -replace '\{\{\s*trans\.pan\s*\}\}', ''
$html = $html -replace '\{\{\s*advancedTran\.showFuel\s*\?\s*[''"]▼[''"]\s*:\s*[''"]▶[''"]\s*\}\}', '▶'
$html = $html -replace '\{\{\s*([^}]+)\s*\}\}', ''

# Remove :disabled bindings
$html = $html -replace '\s+:disabled="[^"]*"', ''

# Remove :value bindings
$html = $html -replace '\s+:value="[^"]*"', ''

# Remove :key bindings
$html = $html -replace '\s+:key="[^"]*"', ''

# Write the static version
$html | Set-Content -Path "index_static.html" -Encoding UTF8

Write-Host "Conversion complete! Created index_static.html"

