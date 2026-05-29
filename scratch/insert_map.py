import re

with open('templates/superadmin.html', 'r', encoding='utf-8') as f:
    html = f.read()

# 1. Insert Leaflet CSS/JS
leaflet_tags = """    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" integrity="sha256-p4NxAoJBhIIN+hmNHrzRCf9tD/miZyoHS5obTRR9BMY=" crossorigin=""/>
    <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js" integrity="sha256-20nQCchB9co0qIjJZRGuk2/Z9VM+kNiyxNV1lvTlZBo=" crossorigin=""></script>
    <style>"""
html = html.replace('    <style>', leaflet_tags)

# 2. Insert Map Container
map_container = """
    <!-- Geographic Map Distribution -->
    <div class="glass-card mb-4" style="border-left: 3px solid var(--neon-magenta);">
        <h5 class="fw-bold mb-3 d-flex align-items-center">
            <i class="bi bi-geo-alt-fill me-2" style="color: var(--neon-magenta);"></i> Active Shop Geographic Distribution
        </h5>
        <div id="shopMap" style="height: 400px; width: 100%; border-radius: 12px; border: 1px solid var(--card-border);"></div>
    </div>

    <!-- Shop Directory & Database Management -->"""
html = html.replace('    <!-- Shop Directory & Database Management -->', map_container)

# 3. Insert View Profile Button
view_btn = """                                <div class="btn-group btn-group-sm w-100">
                                    <button class="btn btn-outline-info border-secondary" onclick="viewProfile({{ shop.id }})"><i class="bi bi-file-person"></i> View Profile</button>
                                    {% if shop.payment_status in ['a', 'e', 'd', 'r'] %}
                                    <button class="btn btn-outline-primary border-secondary" onclick="document.getElementById('plan_shop_id').value='{{ shop.id }}'" data-bs-toggle="modal" data-bs-target="#editPlanModal">Update Plan</button>
                                    {% endif %}"""
html = html.replace("""                                <div class="btn-group btn-group-sm w-100">
                                    {% if shop.payment_status in ['a', 'e', 'd', 'r'] %}
                                    <button class="btn btn-outline-primary border-secondary" onclick="document.getElementById('plan_shop_id').value='{{ shop.id }}'" data-bs-toggle="modal" data-bs-target="#editPlanModal">Update Plan</button>
                                    {% endif %}""", view_btn)

# 4. Insert Modal
modal_html = """    </div>

    <!-- View Profile Modal -->
    <div class="modal fade" id="viewProfileModal" tabindex="-1">
        <div class="modal-dialog modal-dialog-centered modal-lg">
            <div class="modal-content modal-content-custom">
                <div class="modal-header modal-header-custom">
                    <h5 class="modal-title fw-bold text-white"><i class="bi bi-file-person"></i> Shop Profile Information</h5>
                    <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body text-white" id="profileModalContent">
                    Loading profile...
                </div>
            </div>
        </div>
    </div>

    <!-- Send Notice Modal -->"""
html = html.replace('    </div>\n\n    <!-- Send Notice Modal -->', modal_html)

# 5. Insert JS Logic
js_logic = """    <script>
        // Store profiles for modal viewing
        const shopProfiles = {{ profiles | tojson | safe }};
        
        function viewProfile(shopId) {
            const p = shopProfiles[shopId];
            const content = document.getElementById('profileModalContent');
            if (!p) {
                content.innerHTML = '<div class="alert alert-warning border-0">This shop has not filled out their profile yet.</div>';
            } else {
                content.innerHTML = `
                    <div class="row g-3">
                        <div class="col-md-6">
                            <h6 class="text-info fw-bold border-bottom border-secondary pb-1">Business Details</h6>
                            <p class="mb-1"><small class="text-muted">Legal Name:</small><br><strong>${p.legal_name || 'N/A'}</strong></p>
                            <p class="mb-1"><small class="text-muted">Structure:</small><br><strong>${p.structure || 'N/A'}</strong></p>
                            <p class="mb-1"><small class="text-muted">IPA Number:</small><br><strong>${p.ipa_number || 'N/A'}</strong></p>
                            <p class="mb-1"><small class="text-muted">IRC TIN:</small><br><strong>${p.irc_tin || 'N/A'}</strong></p>
                            <p class="mb-1"><small class="text-muted">Activity:</small><br><strong>${p.activity || 'N/A'}</strong></p>
                        </div>
                        <div class="col-md-6">
                            <h6 class="text-info fw-bold border-bottom border-secondary pb-1">Contact & Location</h6>
                            <p class="mb-1"><small class="text-muted">Director / Owner:</small><br><strong>${p.director_name || 'N/A'}</strong></p>
                            <p class="mb-1"><small class="text-muted">Phone:</small><br><strong>${p.contact_phone || 'N/A'}</strong></p>
                            <p class="mb-1"><small class="text-muted">Email:</small><br><strong>${p.contact_email || 'N/A'}</strong></p>
                            <p class="mb-1"><small class="text-muted">Physical Address:</small><br><strong>${p.physical_address || 'N/A'}</strong></p>
                            <p class="mb-1"><small class="text-muted">Postal Address:</small><br><strong>${p.postal_address || 'N/A'}</strong></p>
                            <p class="mb-0"><small class="text-muted">GPS:</small><br><strong>${p.latitude ? p.latitude + ', ' + p.longitude : 'N/A'}</strong></p>
                        </div>
                    </div>
                `;
            }
            new bootstrap.Modal(document.getElementById('viewProfileModal')).show();
        }

        // Initialize Map
        document.addEventListener('DOMContentLoaded', () => {
            const map = L.map('shopMap').setView([-6.314993, 143.95555], 5);
            L.tileLayer('https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png', {
                attribution: '&copy; OpenStreetMap contributors &copy; CARTO'
            }).addTo(map);

            let hasPins = false;
            let bounds = L.latLngBounds();

            const shopsData = {{ shops|tojson }};
            shopsData.forEach(s => {
                if (['a'].includes(s.payment_status)) {
                    const profile = shopProfiles[s.id];
                    if (profile && profile.latitude && profile.longitude) {
                        const lat = parseFloat(profile.latitude);
                        const lng = parseFloat(profile.longitude);
                        if (!isNaN(lat) && !isNaN(lng)) {
                            hasPins = true;
                            bounds.extend([lat, lng]);
                            
                            const marker = L.circleMarker([lat, lng], {
                                radius: 8,
                                fillColor: '#f91a8e',
                                color: '#fff',
                                weight: 2,
                                opacity: 1,
                                fillOpacity: 0.8
                            }).addTo(map);
                            
                            marker.bindPopup(`
                                <div style="color:#000;">
                                    <strong>${s.name}</strong><br>
                                    Owner: @${s.owner_username}<br>
                                    <button class="btn btn-sm btn-info mt-2" onclick="viewProfile(${s.id})">View Details</button>
                                </div>
                            `);
                        }
                    }
                }
            });
            
            if (hasPins) {
                map.fitBounds(bounds, { padding: [50, 50], maxZoom: 14 });
            }
        });
"""
html = html.replace('    <script>', js_logic)

with open('templates/superadmin.html', 'w', encoding='utf-8') as f:
    f.write(html)
print('Done injecting map')
