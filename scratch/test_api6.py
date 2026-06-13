import requests

def test_api():
    # Login via API
    r = requests.post('https://braenova-stockmaster-pos.onrender.com/api/v1/auth/login', json={'username':'wasaadmin','password':'StockMastaMaster2026!'})
    data = r.json()
    token = data['token']
    headers = {'Authorization': f'Bearer {token}'}
    
    # Check opening shift
    r2 = requests.post('https://braenova-stockmaster-pos.onrender.com/api/v1/shifts/open', headers=headers, json={'starting_float': 100.0})
    print('shifts/open:', r2.status_code, r2.text)

if __name__ == '__main__':
    test_api()
