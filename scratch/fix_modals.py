import re

def fix_file(filepath, remove_chart=False):
    with open(filepath, 'r', encoding='utf-8') as f:
        html = f.read()
    
    # Fix Z-index for modal
    if '.modal { z-index: 2000 !important; }' not in html:
        html = html.replace('</style>', '    .modal { z-index: 2000 !important; }\n    .modal-backdrop { z-index: 1999 !important; }\n    </style>')
    
    # Remove Chart JS from shop_profile
    if remove_chart:
        pattern_chart = re.compile(r'<script>\s*new Chart\(document\.getElementById\(\'dailySalesChart.*?setInterval\(syncAlerts, 10000\);\s*</script>', re.DOTALL)
        html = pattern_chart.sub('', html)

    # Fix dismissNotice logic
    replacement_dismiss = """        function dismissNotice(id, btn) {
            let dismissed = JSON.parse(localStorage.getItem('dismissed_notices') || '[]');
            if(!dismissed.includes(id)) {
                dismissed.push(id);
                localStorage.setItem('dismissed_notices', JSON.stringify(dismissed));
            }
            const item = btn.closest('.notice-item');
            if(item) {
                const container = item.closest('.list-group');
                item.remove();
                if (container && container.querySelectorAll('.notice-item, #sysSubAlert').length === 0) {
                    container.innerHTML = `
                        <div class="p-4 text-center text-muted">
                            <span style="font-size: 2rem;"><i class="bi bi-envelope-open"></i></span>
                            <p class="mt-2 mb-0">No new messages.</p>
                        </div>
                    `;
                }
            }
            if (typeof checkUnread === 'function') checkUnread();
        }"""
    html = re.sub(r'function dismissNotice\(id, btn\) \{.*?if\(item\) item\.remove\(\);\s*\}', replacement_dismiss, html, flags=re.DOTALL)

    # Fix DOMContentLoaded logic to show empty state
    replacement_dom = """            dismissed.forEach(id => {
                const item = document.querySelector(`.notice-item[data-notice-id="${id}"]`);
                if(item) item.remove();
            });
            
            const noticeContainer = document.querySelector('#messagesModal .list-group');
            if (noticeContainer && noticeContainer.querySelectorAll('.notice-item, #sysSubAlert').length === 0) {
                noticeContainer.innerHTML = `
                    <div class="p-4 text-center text-muted">
                        <span style="font-size: 2rem;"><i class="bi bi-envelope-open"></i></span>
                        <p class="mt-2 mb-0">No new messages.</p>
                    </div>
                `;
            }"""
    html = re.sub(r'dismissed\.forEach\(id => \{.*?if\(item\) item\.remove\(\);\s*\}\);', replacement_dom, html, flags=re.DOTALL)

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(html)
    print(f'Fixed {filepath}')

fix_file('templates/dashboard.html')
fix_file('templates/pos.html')
fix_file('templates/shop_profile.html', remove_chart=True)
