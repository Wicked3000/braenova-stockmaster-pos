import base64
import os

def get_b64(path):
    if os.path.exists(path):
        with open(path, 'rb') as f:
            return base64.b64encode(f.read()).decode('utf-8')
    return "MISSING"

with open('b64_assets.txt', 'w') as out:
    out.write(f"LOGO:{get_b64('static/logo.png')}\n")
    out.write(f"BG:{get_b64('static/login_bg_shop.png')}\n")
