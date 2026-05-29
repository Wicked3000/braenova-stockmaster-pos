import os
import re

template_dir = r'd:\BraeNova-StockMaster\templates'

# Remove all brand-text divs (with or without nested spans)
pattern = re.compile(r'<div class="brand-text">.*?</div>', re.DOTALL)

for fname in os.listdir(template_dir):
    if not fname.endswith('.html'):
        continue
    path = os.path.join(template_dir, fname)
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    original = content
    content = pattern.sub('', content)
    if content != original:
        with open(path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f'Updated: {fname}')
    else:
        print(f'No match: {fname}')
