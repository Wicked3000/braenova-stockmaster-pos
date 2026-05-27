import os

def update_pos():
    with open('templates/pos.html', 'r', encoding='utf-8') as f:
        content = f.read()

    # Step 1: Prevent page reload and create resetPOS()
    old_close = """        function closeReceipt() {
            receiptModal.hide();
            const pop = document.getElementById('successPop');
            pop.classList.add('show');
            setTimeout(() => {
                pop.classList.remove('show');
                window.location.reload();
            }, 1000);
        }"""
        
    new_close = """        function resetPOS() {
            cart = [];
            currentTotal = 0;
            updateCartUI();
            document.getElementById('itemSearch').value = '';
            filterPOS();
        }

        function closeReceipt() {
            receiptModal.hide();
            const pop = document.getElementById('successPop');
            pop.classList.add('show');
            setTimeout(() => {
                pop.classList.remove('show');
                resetPOS();
            }, 1000);
        }"""
        
    content = content.replace(old_close, new_close)

    # Step 2: Update submitCheckout() with Offline Support
    old_submit = """            const response = await fetch('/api/checkout', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(payload)
            });

            const result = await response.json();

            if (response.ok) {
                checkoutModal.hide();"""
                
    new_submit = """            // Offline Queue Logic
            let isOffline = !navigator.onLine;
            let success = false;
            let result = {};

            if (isOffline) {
                // Save offline
                let queue = JSON.parse(localStorage.getItem('offlineQueue') || '[]');
                payload.timestamp = new Date().toISOString(); // for reference
                queue.push(payload);
                localStorage.setItem('offlineQueue', JSON.stringify(queue));
                success = true; // Assume success for offline queue
                
                // Manually decrement local stock
                payload.items.forEach(item => {
                    if (stockRegistry[item.id]) {
                        stockRegistry[item.id].qty -= item.qty;
                    }
                });
                
                // Notify user
                showError("Sale saved offline! Will sync automatically.", "OFFLINE MODE");
            } else {
                try {
                    const response = await fetch('/api/checkout', {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify(payload)
                    });
                    result = await response.json();
                    if (response.ok) success = true;
                    else {
                        showError(result.message || "Unknown error", "SERVER ERROR");
                        return;
                    }
                } catch(e) {
                    // Fallback if fetch fails (e.g. suddenly disconnected)
                    let queue = JSON.parse(localStorage.getItem('offlineQueue') || '[]');
                    payload.timestamp = new Date().toISOString();
                    queue.push(payload);
                    localStorage.setItem('offlineQueue', JSON.stringify(queue));
                    success = true;
                    showError("Connection lost. Sale saved offline!", "OFFLINE MODE");
                }
            }

            if (success) {
                checkoutModal.hide();"""
                
    content = content.replace(old_submit, new_submit)

    # Step 3: Background Auto-Sync
    sync_code = """        async function syncOfflineQueue() {
            if (!navigator.onLine) return;
            let queue = JSON.parse(localStorage.getItem('offlineQueue') || '[]');
            if (queue.length === 0) return;
            
            // Show sync badge if not exists
            let badge = document.getElementById('offlineBadge');
            if (!badge) {
                badge = document.createElement('div');
                badge.id = 'offlineBadge';
                badge.style.cssText = 'position:fixed; top:10px; right:10px; background:#ff5252; color:#fff; padding:5px 10px; border-radius:20px; z-index:9999; font-weight:bold; font-size:0.8rem; box-shadow:0 2px 10px rgba(0,0,0,0.5);';
                document.body.appendChild(badge);
            }
            badge.innerText = `Syncing ${queue.length} offline sales...`;
            badge.style.display = 'block';

            let remaining = [];
            for (let payload of queue) {
                try {
                    const response = await fetch('/api/checkout', {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify(payload)
                    });
                    if (!response.ok) {
                        remaining.push(payload);
                    }
                } catch(e) {
                    remaining.push(payload); // Keep in queue
                }
            }
            
            localStorage.setItem('offlineQueue', JSON.stringify(remaining));
            if (remaining.length === 0) {
                badge.style.background = '#25D366';
                badge.innerText = 'Sync Complete!';
                setTimeout(() => badge.style.display = 'none', 3000);
            } else {
                badge.innerText = `${remaining.length} sales pending sync...`;
            }
        }
        
        window.addEventListener('online', syncOfflineQueue);
        setInterval(syncOfflineQueue, 15000); // Check every 15s
        setTimeout(syncOfflineQueue, 2000); // Run shortly after load
"""
    # Insert sync code just before the notice formatting script block
    if sync_code not in content:
        target = "        // Format notice times to local timezone"
        content = content.replace(target, sync_code + "\n" + target)

    with open('templates/pos.html', 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    update_pos()
