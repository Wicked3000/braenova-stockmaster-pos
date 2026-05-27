import re
import os

old_code = """@app.route('/superadmin/notice', methods=['POST'])
@login_required
@superadmin_required
def post_notice():
    title = request.form.get('title')
    content = request.form.get('content')
    target_role = request.form.get('target_role')
    if title and content:
        from database import create_notice
        create_notice(title, content, target_role)
        flash("Notice sent successfully.", "success")
    return redirect(url_for('superadmin_dashboard'))"""

new_code = """@app.route('/superadmin/notice', methods=['POST'])
@login_required
@superadmin_required
def post_notice():
    title = request.form.get('title')
    content = request.form.get('content')
    target_role = request.form.get('target_role')
    
    attachment_url = None
    if 'attachment' in request.files:
        file = request.files['attachment']
        if file and file.filename != '':
            import time
            filename = secure_filename(file.filename)
            filename = f"{int(time.time())}_{filename}"
            upload_dir = os.path.join(app.root_path, 'static', 'uploads', 'notices')
            os.makedirs(upload_dir, exist_ok=True)
            filepath = os.path.join(upload_dir, filename)
            file.save(filepath)
            attachment_url = f"/static/uploads/notices/{filename}"
            
    if title and content:
        from database import create_notice
        create_notice(title, content, target_role, attachment_url=attachment_url)
        flash("Notice sent successfully.", "success")
    return redirect(url_for('superadmin_dashboard'))"""

def update_app():
    with open('app.py', 'r', encoding='utf-8') as f:
        content = f.read()
        
    if old_code in content:
        content = content.replace(old_code, new_code)
        with open('app.py', 'w', encoding='utf-8') as f:
            f.write(content)
        print("Updated app.py")
    else:
        print("Code not found")

if __name__ == '__main__':
    update_app()
