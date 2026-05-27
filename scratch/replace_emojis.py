import os
import glob
import re

cdn = '<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.1/font/bootstrap-icons.css">'

replacements = {
    '🛒': '<i class="bi bi-cart"></i>',
    '🔄': '<i class="bi bi-arrow-clockwise"></i>',
    '📜': '<i class="bi bi-receipt"></i>',
    '🌐': '<i class="bi bi-globe"></i>',
    '📉': '<i class="bi bi-graph-down"></i>',
    '💳': '<i class="bi bi-credit-card"></i>',
    '❌': '<i class="bi bi-x-lg"></i>',
    '✉️': '<i class="bi bi-envelope"></i>',
    '✉': '<i class="bi bi-envelope"></i>',
    '👥': '<i class="bi bi-people"></i>',
    '🚫': '<i class="bi bi-ban"></i>',
    '🏪': '<i class="bi bi-shop"></i>',
    '✔️': '<i class="bi bi-check-lg"></i>',
    '✔': '<i class="bi bi-check-lg"></i>',
    '🛡️': '<i class="bi bi-shield"></i>',
    '🛡': '<i class="bi bi-shield"></i>',
    '🧮': '<i class="bi bi-calculator"></i>',
    '⏳': '<i class="bi bi-hourglass-split"></i>',
    '📱': '<i class="bi bi-phone"></i>',
    '⚠️': '<i class="bi bi-exclamation-triangle"></i>',
    '⚠': '<i class="bi bi-exclamation-triangle"></i>',
    '💵': '<i class="bi bi-cash-stack"></i>',
    '🕵️': '<i class="bi bi-incognito"></i>',
    '🕵': '<i class="bi bi-incognito"></i>',
    '📖': '<i class="bi bi-book"></i>',
    '🔔': '<i class="bi bi-bell"></i>',
    '🗑️': '<i class="bi bi-trash"></i>',
    '🗑': '<i class="bi bi-trash"></i>',
    'ℹ️': '<i class="bi bi-info-circle"></i>',
    'ℹ': '<i class="bi bi-info-circle"></i>',
    '⚙️': '<i class="bi bi-gear"></i>',
    '⚙': '<i class="bi bi-gear"></i>',
    '💬': '<i class="bi bi-chat-dots"></i>',
    '📦': '<i class="bi bi-box-seam"></i>',
    '📒': '<i class="bi bi-journal"></i>',
    '🔒': '<i class="bi bi-lock"></i>',
    '⚡': '<i class="bi bi-lightning"></i>',
    '📊': '<i class="bi bi-bar-chart"></i>',
    '☁️': '<i class="bi bi-cloud"></i>',
    '☁': '<i class="bi bi-cloud"></i>',
    '📅': '<i class="bi bi-calendar"></i>',
    '📭': '<i class="bi bi-envelope-open"></i>',
    '🚪': '<i class="bi bi-box-arrow-right"></i>',
    '✅': '<i class="bi bi-check-circle"></i>',
    '🔑': '<i class="bi bi-key"></i>',
    '📢': '<i class="bi bi-megaphone"></i>',
    '➕': '<i class="bi bi-plus-lg"></i>',
}

# Add invisible variation selector variants just in case
for k in list(replacements.keys()):
    if not k.endswith('\uFE0F'):
        replacements[k + '\uFE0F'] = replacements[k]

def apply_replacements():
    files = glob.glob('templates/*.html')
    for f in files:
        with open(f, 'r', encoding='utf-8') as file:
            content = file.read()
            
        # Add CDN if not present
        if 'bootstrap-icons.css' not in content:
            content = content.replace('</head>', f'    {cdn}\n</head>')
            
        # Replace emojis
        for emoji_char, html_tag in replacements.items():
            content = content.replace(emoji_char, html_tag)
            
        # Clean up any orphaned variation selectors
        content = content.replace('\uFE0F', '')
            
        with open(f, 'w', encoding='utf-8') as file:
            file.write(content)
            
    print(f"Processed {len(files)} files successfully.")

if __name__ == '__main__':
    apply_replacements()
