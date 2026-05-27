import os

old_code = """    attachment_url = None
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
            attachment_url = f"/static/uploads/notices/{filename}\""""

new_code = """    attachment_url = None
    if 'attachment' in request.files:
        file = request.files['attachment']
        if file and file.filename != '':
            filename = secure_filename(file.filename)
            upload_dir = os.path.join(app.root_path, 'static', 'uploads', 'notices')
            os.makedirs(upload_dir, exist_ok=True)
            filepath = os.path.join(upload_dir, filename)
            file.save(filepath)
            # The user wants URL to look like /admission-form.pdf
            attachment_url = f"/{filename}\""""

route_code = """
@app.route('/<filename>')
def serve_notice_attachment(filename):
    if filename.lower().endswith('.pdf'):
        from flask import send_from_directory
        import os
        upload_dir = os.path.join(app.root_path, 'static', 'uploads', 'notices')
        return send_from_directory(upload_dir, filename)
    from flask import abort
    abort(404)
"""

def update_app():
    with open('app.py', 'r', encoding='utf-8') as f:
        content = f.read()
        
    if old_code in content:
        content = content.replace(old_code, new_code)
        
        # Append the new route to the bottom of the file
        if 'serve_notice_attachment' not in content:
            content += route_code
            
        with open('app.py', 'w', encoding='utf-8') as f:
            f.write(content)
        print("Updated app.py")
    else:
        print("Code not found")

if __name__ == '__main__':
    update_app()
