import glob

js_old = """        document.addEventListener('DOMContentLoaded', () => {
            let dismissed = JSON.parse(localStorage.getItem('dismissed_notices') || '[]');
            dismissed.forEach(id => {
                const item = document.querySelector(`.notice-item[data-notice-id="${id}"]`);
                if(item) item.remove();
            });
        });"""

js_new = """        document.addEventListener('DOMContentLoaded', () => {
            let dismissed = JSON.parse(localStorage.getItem('dismissed_notices') || '[]');
            let viewed = JSON.parse(localStorage.getItem('viewed_notices') || '[]');
            
            dismissed.forEach(id => {
                const item = document.querySelector(`.notice-item[data-notice-id="${id}"]`);
                if(item) item.remove();
            });

            // Hide dot if all messages have been viewed
            const checkUnread = () => {
                let hasUnread = false;
                document.querySelectorAll('.notice-item').forEach(item => {
                    const id = item.dataset.noticeId;
                    if (!viewed.includes(id)) hasUnread = true;
                });
                
                const sysAlert = document.getElementById('sysSubAlert');
                if (sysAlert && !viewed.includes('sysSubAlert')) {
                    hasUnread = true;
                }

                if (!hasUnread) {
                    document.querySelectorAll('[data-bs-target="#messagesModal"] .bg-danger').forEach(dot => {
                        dot.style.setProperty('display', 'none', 'important');
                    });
                }
            };
            
            checkUnread();

            // When modal opens, hide dot and mark visible messages as viewed
            const modalEl = document.getElementById('messagesModal');
            if (modalEl) {
                modalEl.addEventListener('show.bs.modal', () => {
                    document.querySelectorAll('[data-bs-target="#messagesModal"] .bg-danger').forEach(dot => {
                        dot.style.setProperty('display', 'none', 'important');
                    });
                    
                    document.querySelectorAll('.notice-item').forEach(item => {
                        const id = item.dataset.noticeId;
                        if (!viewed.includes(id)) viewed.push(id);
                    });
                    const sysAlert = document.getElementById('sysSubAlert');
                    if (sysAlert && !viewed.includes('sysSubAlert')) {
                        viewed.push('sysSubAlert');
                    }
                    localStorage.setItem('viewed_notices', JSON.stringify(viewed));
                });
            }
        });"""

def update_dot_logic():
    for f in ['templates/dashboard.html', 'templates/pos.html']:
        with open(f, 'r', encoding='utf-8') as file:
            content = file.read()
            
        if js_old in content:
            content = content.replace(js_old, js_new)
        
        # add id to system alert
        sub_old = '<div class="list-group-item bg-black border-bottom border-secondary p-3">\n                            <div class="d-flex w-100 justify-content-between mb-1">\n                                <h6 class="mb-1 text-danger fw-bold"><i class="bi bi-exclamation-triangle"></i> SYSTEM ALERT: Subscription</h6>'
        sub_new = '<div class="list-group-item bg-black border-bottom border-secondary p-3" id="sysSubAlert">\n                            <div class="d-flex w-100 justify-content-between mb-1">\n                                <h6 class="mb-1 text-danger fw-bold"><i class="bi bi-exclamation-triangle"></i> SYSTEM ALERT: Subscription</h6>'
        
        if sub_old in content:
            content = content.replace(sub_old, sub_new)
            
        with open(f, 'w', encoding='utf-8') as file:
            file.write(content)
            
    print("Notification dot logic updated.")

if __name__ == '__main__':
    update_dot_logic()
