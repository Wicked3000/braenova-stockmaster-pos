import glob

old_html = """                            <p class="mb-1 small text-light" style="white-space: pre-wrap;">{{ notice.content }}</p>
                        </div>"""

new_html = """                            <p class="mb-1 small text-light" style="white-space: pre-wrap;">{{ notice.content }}</p>
                            {% if notice.attachment_url %}
                            <div class="mt-2">
                                <a href="{{ notice.attachment_url }}" target="_blank" class="btn btn-sm btn-outline-info rounded-pill px-3 py-1" style="font-size: 0.75rem;"><i class="bi bi-file-earmark-pdf"></i> View Attachment</a>
                            </div>
                            {% endif %}
                        </div>"""

def update_templates():
    for f in ['templates/dashboard.html', 'templates/pos.html']:
        with open(f, 'r', encoding='utf-8') as file:
            content = file.read()
            
        if old_html in content:
            content = content.replace(old_html, new_html)
            with open(f, 'w', encoding='utf-8') as file:
                file.write(content)
            print(f"Updated {f}")
        else:
            print(f"Code not found in {f}")

if __name__ == '__main__':
    update_templates()
