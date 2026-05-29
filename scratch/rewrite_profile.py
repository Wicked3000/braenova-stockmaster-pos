import re
with open('templates/shop_profile.html', 'r', encoding='utf-8') as f:
    html = f.read()

pattern = re.compile(r'(<div class=\"container py-3\">).*?(<!-- Navigation -->)', re.DOTALL)

form_html = """<div class="container py-3">
    <div class="d-flex justify-content-between align-items-center mb-4">
        <h4 class="fw-bold text-white mb-0"><i class="bi bi-building me-2"></i> Shop Profile</h4>
        <a href="/" class="btn btn-outline-secondary btn-sm rounded-pill px-3">Back to Dash</a>
    </div>

    {% with messages = get_flashed_messages(with_categories=true) %}
        {% if messages %}
            {% for category, message in messages %}
                <div class="alert alert-{{ 'success' if category == 'success' else 'danger' }} py-2 px-3 border-0 rounded-3 mb-4" style="font-size: 0.85rem;">
                    {{ message }}
                </div>
            {% endfor %}
        {% endif %}
    {% endwith %}

    <div class="glass-card p-4 mb-5" style="background: rgba(20,20,20,0.8);">
        <form action="/shops/profile" method="POST">
            <h6 class="text-info text-uppercase fw-bold mb-3 border-bottom border-secondary pb-2">1. Regulatory & Compliance</h6>
            <div class="row g-3 mb-4">
                <div class="col-md-6">
                    <label class="small text-muted mb-1">Legal Business Name</label>
                    <input type="text" name="legal_name" class="form-control bg-dark text-white border-secondary" value="{{ profile.legal_name if profile else '' }}" placeholder="e.g. StockMasta Trading Ltd">
                </div>
                <div class="col-md-6">
                    <label class="small text-muted mb-1">Business Structure</label>
                    <select name="structure" class="form-select bg-dark text-white border-secondary">
                        <option value="" disabled {% if not profile or not profile.structure %}selected{% endif %}>Select Structure</option>
                        <option value="Sole Trader" {% if profile and profile.structure == 'Sole Trader' %}selected{% endif %}>Sole Trader</option>
                        <option value="Company" {% if profile and profile.structure == 'Company' %}selected{% endif %}>Company (Ltd)</option>
                        <option value="Business Group" {% if profile and profile.structure == 'Business Group' %}selected{% endif %}>Business Group</option>
                        <option value="Association" {% if profile and profile.structure == 'Association' %}selected{% endif %}>Association</option>
                    </select>
                </div>
                <div class="col-md-6">
                    <label class="small text-muted mb-1">IPA Registration Number</label>
                    <input type="text" name="ipa_number" class="form-control bg-dark text-white border-secondary" value="{{ profile.ipa_number if profile else '' }}" placeholder="e.g. 1-123456">
                </div>
                <div class="col-md-6">
                    <label class="small text-muted mb-1">IRC TIN (Taxpayer ID)</label>
                    <input type="text" name="irc_tin" class="form-control bg-dark text-white border-secondary" value="{{ profile.irc_tin if profile else '' }}" placeholder="e.g. 100123456">
                </div>
            </div>

            <h6 class="text-info text-uppercase fw-bold mb-3 border-bottom border-secondary pb-2">2. Location & Addresses</h6>
            <div class="row g-3 mb-4">
                <div class="col-md-12">
                    <label class="small text-muted mb-1">Physical Operating Address</label>
                    <input type="text" name="physical_address" class="form-control bg-dark text-white border-secondary" value="{{ profile.physical_address if profile else '' }}" placeholder="Lot, Section, Suburb, Province">
                </div>
                <div class="col-md-12">
                    <label class="small text-muted mb-1">Postal Address</label>
                    <input type="text" name="postal_address" class="form-control bg-dark text-white border-secondary" value="{{ profile.postal_address if profile else '' }}" placeholder="e.g. PO Box XXX, Boroko, NCD">
                </div>
                
                <div class="col-md-12">
                    <label class="small text-muted mb-1 d-block">GPS Coordinates (Map Location)</label>
                    <div class="input-group mb-2">
                        <input type="text" name="latitude" id="lat_input" class="form-control bg-dark text-white border-secondary" value="{{ profile.latitude if profile else '' }}" placeholder="Latitude" readonly>
                        <input type="text" name="longitude" id="lng_input" class="form-control bg-dark text-white border-secondary border-start-0" value="{{ profile.longitude if profile else '' }}" placeholder="Longitude" readonly>
                        <button type="button" class="btn btn-info fw-bold" onclick="captureLocation()"><i class="bi bi-geo-alt-fill"></i> Capture My Location</button>
                    </div>
                    <small class="text-muted" id="geo_status">Used by Super Admins to plot your shop on the map.</small>
                </div>
            </div>

            <h6 class="text-info text-uppercase fw-bold mb-3 border-bottom border-secondary pb-2">3. Contact & Operations</h6>
            <div class="row g-3 mb-4">
                <div class="col-md-12">
                    <label class="small text-muted mb-1">Director / Owner Name</label>
                    <input type="text" name="director_name" class="form-control bg-dark text-white border-secondary" value="{{ profile.director_name if profile else '' }}" placeholder="Full Name">
                </div>
                <div class="col-md-6">
                    <label class="small text-muted mb-1">Primary Contact Number</label>
                    <input type="text" name="contact_phone" class="form-control bg-dark text-white border-secondary" value="{{ profile.contact_phone if profile else '' }}" placeholder="Digicel / Bmobile / Telikom">
                </div>
                <div class="col-md-6">
                    <label class="small text-muted mb-1">Business Email Address</label>
                    <input type="email" name="contact_email" class="form-control bg-dark text-white border-secondary" value="{{ profile.contact_email if profile else '' }}" placeholder="name@company.com.pg">
                </div>
                <div class="col-md-12">
                    <label class="small text-muted mb-1">Primary Business Activity</label>
                    <input type="text" name="activity" class="form-control bg-dark text-white border-secondary" value="{{ profile.activity if profile else '' }}" placeholder="e.g. Wholesale, Trade Store, Fashion Retail">
                </div>
            </div>

            <div class="d-grid mt-4">
                <button type="submit" class="btn btn-success py-3 fw-bold rounded-3 shadow-lg fs-5">SAVE PROFILE</button>
            </div>
        </form>
    </div>
</div>
"""

new_html = pattern.sub(form_html + r'\n    \2', html)

# Inject JS for geolocation
js = """
<script>
function captureLocation() {
    const btn = event.currentTarget;
    const status = document.getElementById('geo_status');
    const latIn = document.getElementById('lat_input');
    const lngIn = document.getElementById('lng_input');
    
    btn.innerHTML = '<span class="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span> Locating...';
    btn.disabled = true;
    
    if (!navigator.geolocation) {
        status.textContent = 'Geolocation is not supported by your browser.';
        status.className = 'text-danger small';
        btn.innerHTML = '<i class="bi bi-geo-alt-fill"></i> Capture My Location';
        btn.disabled = false;
        return;
    }
    
    navigator.geolocation.getCurrentPosition(
        (position) => {
            latIn.value = position.coords.latitude;
            lngIn.value = position.coords.longitude;
            status.textContent = 'Location successfully captured!';
            status.className = 'text-success small fw-bold';
            btn.innerHTML = '<i class="bi bi-check-circle-fill"></i> Captured';
            btn.classList.replace('btn-info', 'btn-success');
        },
        (error) => {
            let msg = 'Unable to retrieve your location.';
            if (error.code === 1) msg = 'Location access denied. Please allow location permissions in your browser.';
            status.textContent = msg;
            status.className = 'text-danger small';
            btn.innerHTML = '<i class="bi bi-geo-alt-fill"></i> Try Again';
            btn.disabled = false;
        },
        { enableHighAccuracy: true, timeout: 10000 }
    );
}
</script>
"""

new_html = new_html.replace('</body>', js + '\n</body>')

with open('templates/shop_profile.html', 'w', encoding='utf-8') as f:
    f.write(new_html)
print('Done rewriting')
