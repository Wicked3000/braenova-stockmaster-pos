import os

def update_landing():
    with open('templates/landing.html', 'r', encoding='utf-8') as f:
        content = f.read()

    # Step 1: Add Toggle Switch before the pricing cards
    target = """        <div style="max-width: 1100px; margin: 0 auto; display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 30px; align-items: stretch; padding-top: 20px;">"""
    
    toggle_html = """        <!-- Billing Cycle Toggle -->
        <div class="d-flex justify-content-center align-items-center mb-5 gap-3">
            <span id="monthlyLabel" class="fw-bold" style="color: #fff; font-size: 1.1rem; transition: color 0.3s;">Monthly</span>
            <div class="form-check form-switch" style="margin: 0; padding-left: 0;">
                <input class="form-check-input" type="checkbox" role="switch" id="billingCycleToggle" onchange="toggleBillingCycle()" style="width: 60px; height: 30px; margin-left: 0; cursor: pointer; background-color: #028bd9; border-color: #028bd9;">
            </div>
            <span id="yearlyLabel" class="fw-bold" style="color: #888; font-size: 1.1rem; transition: color 0.3s;">Yearly <span class="badge rounded-pill bg-success ms-1" style="font-size: 0.7rem; vertical-align: middle;">Get 2 Months Free</span></span>
        </div>

        <div style="max-width: 1100px; margin: 0 auto; display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 30px; align-items: stretch; padding-top: 20px;">"""

    if "Billing Cycle Toggle" not in content:
        content = content.replace(target, toggle_html)

    # Step 2: Update prices to have spans we can target with JS
    old_starter_price = """<span style="font-size: 1.2rem; vertical-align: middle; color: #888;">K</span>50<span style="font-size: 0.9rem; color: #666; font-weight: 600;"> / month</span>"""
    new_starter_price = """<span style="font-size: 1.2rem; vertical-align: middle; color: #888;">K</span><span class="price-val" data-monthly="50" data-yearly="500">50</span><span class="price-period" style="font-size: 0.9rem; color: #666; font-weight: 600;"> / month</span>"""
    content = content.replace(old_starter_price, new_starter_price)

    old_pro_price = """<span style="font-size: 1.5rem; vertical-align: middle; color: #028bd9;">K</span>200<span style="font-size: 1rem; color: #888; font-weight: 600;"> / month</span>"""
    new_pro_price = """<span style="font-size: 1.5rem; vertical-align: middle; color: #028bd9;">K</span><span class="price-val" data-monthly="200" data-yearly="2000">200</span><span class="price-period" style="font-size: 1rem; color: #888; font-weight: 600;"> / month</span>"""
    content = content.replace(old_pro_price, new_pro_price)

    old_multi_price = """<span style="font-size: 1.2rem; vertical-align: middle; color: #888;">K</span>450<span style="font-size: 0.9rem; color: #666; font-weight: 600;"> / month</span>"""
    new_multi_price = """<span style="font-size: 1.2rem; vertical-align: middle; color: #888;">K</span><span class="price-val" data-monthly="450" data-yearly="4500">450</span><span class="price-period" style="font-size: 0.9rem; color: #666; font-weight: 600;"> / month</span>"""
    content = content.replace(old_multi_price, new_multi_price)
    
    # Step 3: Update CTA buttons to have a class we can target
    old_starter_btn = """<a href="/register?plan=starter" class="btn btn-outline-glow rounded-pill" style="border: 2px solid #555; color: #ddd; font-weight: 700; padding: 12px; width: 100%;">Subscribe Now</a>"""
    new_starter_btn = """<a href="/register?plan=starter&cycle=monthly" class="btn btn-outline-glow rounded-pill plan-cta" data-plan="starter" style="border: 2px solid #555; color: #ddd; font-weight: 700; padding: 12px; width: 100%;">Subscribe Now</a>"""
    content = content.replace(old_starter_btn, new_starter_btn)
    
    old_pro_btn = """<a href="/register?plan=pro" class="btn-glow" style="display: block; width: 100%; padding: 15px;">Subscribe Now</a>"""
    new_pro_btn = """<a href="/register?plan=pro&cycle=monthly" class="btn-glow plan-cta" data-plan="pro" style="display: block; width: 100%; padding: 15px;">Subscribe Now</a>"""
    content = content.replace(old_pro_btn, new_pro_btn)
    
    old_multi_btn = """<a href="/register?plan=multi" class="btn btn-outline-glow rounded-pill" style="border: 2px solid #555; color: #ddd; font-weight: 700; padding: 12px; width: 100%;">Subscribe Now</a>"""
    new_multi_btn = """<a href="/register?plan=multi&cycle=monthly" class="btn btn-outline-glow rounded-pill plan-cta" data-plan="multi" style="border: 2px solid #555; color: #ddd; font-weight: 700; padding: 12px; width: 100%;">Subscribe Now</a>"""
    content = content.replace(old_multi_btn, new_multi_btn)

    # Step 4: Add Javascript Logic
    js_code = """
    <!-- Billing Toggle Script -->
    <script>
        function toggleBillingCycle() {
            const isYearly = document.getElementById('billingCycleToggle').checked;
            const monthlyLabel = document.getElementById('monthlyLabel');
            const yearlyLabel = document.getElementById('yearlyLabel');
            
            if (isYearly) {
                monthlyLabel.style.color = '#888';
                yearlyLabel.style.color = '#fff';
            } else {
                monthlyLabel.style.color = '#fff';
                yearlyLabel.style.color = '#888';
            }

            document.querySelectorAll('.price-val').forEach(el => {
                // simple pop animation
                el.style.transform = 'scale(0.8)';
                el.style.opacity = '0';
                setTimeout(() => {
                    el.innerText = isYearly ? el.getAttribute('data-yearly') : el.getAttribute('data-monthly');
                    el.style.transform = 'scale(1)';
                    el.style.opacity = '1';
                }, 150);
            });
            
            document.querySelectorAll('.price-period').forEach(el => {
                setTimeout(() => {
                    el.innerText = isYearly ? ' / year' : ' / month';
                }, 150);
            });

            document.querySelectorAll('.plan-cta').forEach(el => {
                const plan = el.getAttribute('data-plan');
                const cycle = isYearly ? 'yearly' : 'monthly';
                el.href = `/register?plan=${plan}&cycle=${cycle}`;
            });
        }
        
        // Add CSS transition for smooth price popping
        document.head.insertAdjacentHTML('beforeend', '<style>.price-val { display: inline-block; transition: all 0.15s ease-in-out; }</style>');
    </script>
    """
    
    if "toggleBillingCycle()" not in content:
        content = content.replace("</body>", js_code + "\n</body>")

    with open('templates/landing.html', 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    update_landing()
