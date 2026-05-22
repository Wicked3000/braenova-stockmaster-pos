import sys
import os
sys.path.append(os.path.abspath('.'))
from app import app
with app.test_client() as c:
    with c.session_transaction() as sess:
        sess['user_id'] = 1
        sess['username'] = 'admin'
        sess['role'] = 'owner'
    
    resp = c.get('/inventory')
    print("Status:", resp.status_code)
    if resp.status_code == 500:
        print("500 ERROR CAPTURED. Check server logs.")
    else:
        print("Success!")
