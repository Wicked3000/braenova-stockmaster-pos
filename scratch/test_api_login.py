import requests

resp = requests.post('http://127.0.0.1:5000/api/v1/auth/login', json={
    'username': 'admin',
    'password': 'password'
})
print("Status:", resp.status_code)
print("Text:", resp.text)
