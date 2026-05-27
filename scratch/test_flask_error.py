import sys
import os
sys.path.append(os.path.abspath('.'))
from app import app
from database import verify_user

def test_login():
    app.config['TESTING'] = True
    app.config['WTF_CSRF_ENABLED'] = False
    
    with app.test_client() as client:
        # Try to login as owner
        print("Logging in as owner...")
        rv = client.post('/login', data=dict(
            username='admin',
            password='admin123'
        ), follow_redirects=True)
        
        print("Status Code:", rv.status_code)
        if rv.status_code == 500:
            print("500 ERROR CAUGHT!")
            print(rv.data.decode('utf-8'))
        else:
            print("Login successful, page loaded.")
            
        # Try to login as cashier
        print("\nLogging in as cashier...")
        rv = client.post('/login', data=dict(
            username='staff',
            password='cashier123'
        ), follow_redirects=True)
        
        print("Status Code:", rv.status_code)
        if rv.status_code == 500:
            print("500 ERROR CAUGHT!")
            print(rv.data.decode('utf-8'))
        else:
            print("Login successful, page loaded.")

if __name__ == '__main__':
    test_login()
