import sys
import os
from unittest.mock import patch
sys.path.append(os.path.abspath('.'))

from app import app

def run_tests():
    print("=== STARTING SUPERADMIN SHOP DELETION TESTS ===")
    
    with app.test_client() as client:
        # Test 1: Anonymous access to delete route should redirect to login
        print("\nTest 1: Anonymous Access Block")
        resp = client.post('/superadmin/delete-shop', data={'shop_id': '123'})
        print(f"Status code: {resp.status_code}")
        print(f"Redirect location: {resp.location}")
        assert resp.status_code == 302
        assert "/login" in resp.location
        print("Test 1 Passed!")

        # Test 2: Non-superadmin role (e.g. owner) access should redirect to dashboard with unauthorized access flash
        print("\nTest 2: Non-Superadmin Access Block")
        with client.session_transaction() as sess:
            sess['user_id'] = 1
            sess['username'] = 'shopowner'
            sess['role'] = 'owner'
            sess['shop_id'] = 1
            sess['plan'] = 'starter'
        
        resp = client.post('/superadmin/delete-shop', data={'shop_id': '123'}, follow_redirects=True)
        print(f"Final URL: {resp.request.path}")
        html = resp.get_data(as_text=True)
        assert "Unauthorized Access" in html
        print("Test 2 Passed!")

        # Test 3: Superadmin access with missing shop_id
        print("\nTest 3: Superadmin Missing Shop ID")
        with client.session_transaction() as sess:
            sess['user_id'] = 999
            sess['username'] = 'superadmin'
            sess['role'] = 'superadmin'
            if 'shop_id' in sess:
                del sess['shop_id']
        
        # We need to mock get_all_shops for the redirect render
        with patch('app.get_all_shops', return_value=[]):
            resp = client.post('/superadmin/delete-shop', data={}, follow_redirects=True)
            html = resp.get_data(as_text=True)
            assert "Shop ID is required." in html
            print("Test 3 Passed!")

        # Test 4: Superadmin access with non-existent shop_id
        print("\nTest 4: Superadmin Non-Existent Shop ID")
        with patch('database.supabase') as mock_supabase, \
             patch('app.get_all_shops', return_value=[]):
            # Mock select returning empty data
            mock_select = mock_supabase.table.return_value.select.return_value.eq.return_value
            mock_select.execute.return_value.data = []
            
            resp = client.post('/superadmin/delete-shop', data={'shop_id': '9999'}, follow_redirects=True)
            html = resp.get_data(as_text=True)
            assert "Shop not found." in html
            print("Test 4 Passed!")

        # Test 5: Superadmin successful shop deletion
        print("\nTest 5: Superadmin Successful Deletion")
        with patch('database.supabase') as mock_supabase, \
             patch('app.delete_shop_and_data') as mock_delete_func, \
             patch('app.get_all_shops', return_value=[]):
            
            # Mock select returning shop name
            mock_select = mock_supabase.table.return_value.select.return_value.eq.return_value
            mock_select.execute.return_value.data = [{'name': 'Target Shop'}]
            
            resp = client.post('/superadmin/delete-shop', data={'shop_id': '100'}, follow_redirects=True)
            html = resp.get_data(as_text=True)
            
            mock_delete_func.assert_called_once_with('100')
            assert "Shop &#39;Target Shop&#39; and all associated users/data have been permanently deleted." in html or "Shop 'Target Shop' and all associated users/data have been permanently deleted." in html
            print("Test 5 Passed!")

    print("\n=== ALL SUPERADMIN DELETION TESTS PASSED SUCCESSFULLY! ===")

if __name__ == '__main__':
    run_tests()
