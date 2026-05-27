import glob

js_snippet = """
    <script>
        // Format notice times to local timezone
        document.querySelectorAll('.notice-time').forEach(el => {
            if(el.dataset.iso) {
                const d = new Date(el.dataset.iso);
                if(!isNaN(d)) {
                    el.textContent = d.toLocaleDateString(undefined, {day:'numeric', month:'short'}) + ' ' + d.toLocaleTimeString(undefined, {hour:'2-digit', minute:'2-digit', hour12: false});
                }
            }
        });

        // Handle notice dismissal via localStorage
        function dismissNotice(id, btn) {
            let dismissed = JSON.parse(localStorage.getItem('dismissed_notices') || '[]');
            if(!dismissed.includes(id)) {
                dismissed.push(id);
                localStorage.setItem('dismissed_notices', JSON.stringify(dismissed));
            }
            const item = btn.closest('.notice-item');
            if(item) item.remove();
        }

        document.addEventListener('DOMContentLoaded', () => {
            let dismissed = JSON.parse(localStorage.getItem('dismissed_notices') || '[]');
            dismissed.forEach(id => {
                const item = document.querySelector(`.notice-item[data-notice-id="${id}"]`);
                if(item) item.remove();
            });
        });
    </script>
"""

old_html = """                        {% for notice in notices %}
                        <div class="list-group-item bg-black border-bottom border-secondary p-3">
                            <div class="d-flex w-100 justify-content-between mb-1">
                                <h6 class="mb-1 text-info fw-bold">{{ notice.title }}</h6>
                                <small class="text-muted">{{ notice.created_at.strftime('%d %b %H:%M') if notice.created_at else '' }}</small>
                            </div>
                            <p class="mb-1 small text-light" style="white-space: pre-wrap;">{{ notice.content }}</p>
                        </div>"""

new_html = """                        {% for notice in notices %}
                        <div class="list-group-item bg-black border-bottom border-secondary p-3 notice-item" data-notice-id="{{ notice.id }}">
                            <div class="d-flex w-100 justify-content-between align-items-start mb-1">
                                <h6 class="mb-1 text-info fw-bold">{{ notice.title }}</h6>
                                <div class="d-flex align-items-center gap-2">
                                    <small class="text-muted notice-time" data-iso="{{ notice.created_at.isoformat() if notice.created_at else '' }}">{{ notice.created_at.strftime('%d %b %H:%M') if notice.created_at else '' }}</small>
                                    <button class="btn btn-sm btn-link text-danger p-0 border-0" onclick="dismissNotice({{ notice.id }}, this)" title="Delete Message"><i class="bi bi-trash"></i></button>
                                </div>
                            </div>
                            <p class="mb-1 small text-light" style="white-space: pre-wrap;">{{ notice.content }}</p>
                        </div>"""

def update_modals():
    for f in ['templates/dashboard.html', 'templates/pos.html']:
        with open(f, 'r', encoding='utf-8') as file:
            content = file.read()
            
        # Replace the HTML block
        content = content.replace(old_html, new_html)
        
        # Inject JS before closing body if not already present
        if 'function dismissNotice' not in content:
            content = content.replace('</body>', f'{js_snippet}\n</body>')
            
        with open(f, 'w', encoding='utf-8') as file:
            file.write(content)
            
    print("Modals and JS updated.")

if __name__ == '__main__':
    update_modals()
