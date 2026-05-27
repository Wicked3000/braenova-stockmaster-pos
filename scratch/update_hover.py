import os

css_code = """
        .btn-whatsapp {
            font-size: 1.1rem;
            background-color: #25D366;
            border-color: #25D366;
            color: #111;
            transition: all 0.3s ease;
        }
        .btn-whatsapp:hover {
            background-color: #128C7E;
            border-color: #128C7E;
            color: #fff;
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(37, 211, 102, 0.4);
        }
"""

old_btn = '<a href="https://wa.me/67570000000" target="_blank" class="btn w-100 fw-bold rounded-pill py-3" style="font-size: 1.1rem; background-color: #25D366; border-color: #25D366; color: #111;"><i class="bi bi-whatsapp"></i> WhatsApp Support</a>'
new_btn = '<a href="https://wa.me/67570000000" target="_blank" class="btn btn-whatsapp w-100 fw-bold rounded-pill py-3"><i class="bi bi-whatsapp"></i> WhatsApp Support</a>'

def apply_hover():
    for f in ['templates/dashboard.html', 'templates/pos.html']:
        with open(f, 'r', encoding='utf-8') as file:
            content = file.read()
            
        if old_btn in content:
            content = content.replace(old_btn, new_btn)
            
            # Find the closing </style> tag and insert before it
            if '</style>' in content:
                content = content.replace('</style>', css_code + '\n    </style>', 1)
                
            with open(f, 'w', encoding='utf-8') as file:
                file.write(content)
            print(f"Updated {f}")
        else:
            print(f"Code not found in {f}")

if __name__ == '__main__':
    apply_hover()
