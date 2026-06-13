import requests

def test_api():
    # Login
    r = requests.post('http://127.0.0.1:5000/api/v1/auth/login', json={'username':'superadmin','password':'password'})
    data = r.json()
    if not data.get('success'):
        print('Login failed:', data)
        return
    token = data['token']
    headers = {'Authorization': f'Bearer {token}'}
    
    # Check shifts
    r2 = requests.get('http://127.0.0.1:5000/api/v1/shifts/current', headers=headers)
    print('shifts/current:', r2.status_code, r2.text)
    
    # Check inventory
    r3 = requests.get('http://127.0.0.1:5000/api/v1/inventory', headers=headers)
    print('inventory:', r3.status_code)
    if r3.status_code == 500:
        print(r3.text)
        
    # Check categories
    r4 = requests.get('http://127.0.0.1:5000/api/v1/categories', headers=headers)
    print('categories:', r4.status_code)
    if r4.status_code == 500:
        print(r4.text)

if __name__ == '__main__':
    test_api()
