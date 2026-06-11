from app import app
import unittest

class TestLogin(unittest.TestCase):
    def setUp(self):
        self.app = app.test_client()

    def test_login_get(self):
        resp = self.app.get('/login')
        print("GET /login status:", resp.status_code)

    def test_login_post(self):
        # Even with no database, let's see if it throws a Werkzeug 500 
        # or if it just fails authentication.
        resp = self.app.post('/login', data=dict(username="admin", password="password"))
        print("POST /login status:", resp.status_code)

if __name__ == '__main__':
    unittest.main()
