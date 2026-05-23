import sys
import os
from unittest.mock import patch
sys.path.append(os.path.abspath('.'))

from app import app

def run_tests():
    print("=== STARTING PLAN ENFORCEMENT TESTS ===")
    
    with app.test_client() as client:
        # Test 1: Starter Plan Dinau Checkout Block
        print("\nTest 1: Starter Plan Dinau Checkout Block")
        with client.session_transaction() as sess:
            sess['user_id'] = 6  # vadmin
            sess['username'] = 'vadmin'
            sess['role'] = 'owner'
            sess['shop_id'] = 4  # VBOY (starter plan)
            sess['plan'] = 'starter'

        resp = client.post('/api/checkout', json={
            'items': [{'id': 1, 'qty': 1, 'total_price': 25.0}],
            'payment_method': 'dinau',
            'customer_name': 'Joe Smith'
        })
        print(f"Status code: {resp.status_code}")
        print(f"JSON response: {resp.get_json()}")
        assert resp.status_code == 400
        assert "Store credit (Dinau) is not available" in resp.get_json()['message']
        print("Test 1 Passed!")

        # Test 2: Starter Plan Cashier Limit Block (> 1 cashier)
        print("\nTest 2: Starter Plan Cashier Limit Block")
        # Mock get_all_cashiers to return 1 cashier already
        with patch('app.get_all_cashiers') as mock_get_cashiers:
            mock_get_cashiers.return_value = [{'id': 99, 'username': 'cashier1', 'role': 'cashier'}]
            
            # Post new cashier
            resp = client.post('/users/add', data={
                'username': 'new_cashier',
                'password': 'password123'
            }, follow_redirects=True)
            
            print(f"Final URL: {resp.request.path}")
            # Check flash messages (stored in session or HTML)
            html = resp.get_data(as_text=True)
            assert "Starter plan limit reached" in html
            print("Test 2 Passed!")

        # Test 3: Starter Plan Product Limit Block (> 100 products)
        print("\nTest 3: Starter Plan Product Limit Block")
        # Mock get_all_inventory to return 100 dummy items with all keys needed for templates
        dummy_inventory = [{
            'id': i,
            'item_name': f'Item {i}',
            'quantity': 5,
            'category': 'General',
            'unit_price': 10.0,
            'cost_price': 8.0,
            'min_threshold': 2
        } for i in range(100)]
        with patch('app.get_all_inventory') as mock_get_inventory:
            mock_get_inventory.return_value = dummy_inventory
            
            resp = client.post('/inventory/add', data={
                'item_name': 'OverLimitItem',
                'quantity': 10,
                'threshold': 2,
                'cost': 1.0,
                'price': 2.0,
                'category': 'General'
            }, follow_redirects=True)
            
            html = resp.get_data(as_text=True)
            assert "Starter plan limit reached" in html
            print("Test 3 Passed!")

        # Test 4: Centralized Inventory Block for Starter/Pro Shop Plans
        print("\nTest 4: Centralized Inventory Block for Pro Shop")
        with client.session_transaction() as sess:
            sess['plan'] = 'pro'  # Set to Pro
            
        resp = client.get('/inventory/centralized', follow_redirects=True)
        html = resp.get_data(as_text=True)
        assert "Upgrade to Multi-Shop plan" in html
        print("Test 4 Passed!")

        # Test 5: Centralized Inventory Allow for Multi-Shop Plan
        print("\nTest 5: Centralized Inventory Allowed for Multi-Shop")
        with client.session_transaction() as sess:
            sess['user_id'] = 1  # owner admin
            sess['plan'] = 'multi'  # Set to Multi-Shop
            
        with patch('app.get_centralized_inventory') as mock_centralized:
            mock_centralized.return_value = [
                {'id': 1, 'item_name': 'Bread', 'shop_name': 'Base Shop', 'category': 'General', 'cost_price': 2.0, 'unit_price': 3.5, 'quantity': 10, 'min_threshold': 5},
                {'id': 2, 'item_name': 'Butter', 'shop_name': 'Branch Shop', 'category': 'General', 'cost_price': 3.0, 'unit_price': 5.0, 'quantity': 2, 'min_threshold': 5}
            ]
            
            resp = client.get('/inventory/centralized')
            html = resp.get_data(as_text=True)
            assert "Consolidated Inventory" in html
            assert "Base Shop" in html
            assert "Branch Shop" in html
            assert "Butter" in html
            print("Test 5 Passed!")

        # Test 6: Cashier Sales Log Access
        print("\nTest 6: Cashier Sales Log Access")
        with client.session_transaction() as sess:
            sess['user_id'] = 2  # cashier staff
            sess['username'] = 'staff'
            sess['role'] = 'cashier'
            sess['shop_id'] = 1
            sess['plan'] = 'starter'
        with patch('app.get_sales_history') as mock_sales_history:
            mock_sales_history.return_value = []
            resp = client.get('/sales-log')
            print(f"Status code: {resp.status_code}")
            assert resp.status_code == 200
            print("Test 6 Passed!")

        # Test 7: Owner Sales Log Access
        print("\nTest 7: Owner Sales Log Access")
        with client.session_transaction() as sess:
            sess['user_id'] = 1  # owner admin
            sess['username'] = 'admin'
            sess['role'] = 'owner'
            sess['shop_id'] = 1
            sess['plan'] = 'starter'
        with patch('app.get_sales_history') as mock_sales_history:
            mock_sales_history.return_value = []
            resp = client.get('/sales-log')
            print(f"Status code: {resp.status_code}")
            assert resp.status_code == 200
            print("Test 7 Passed!")

    print("\n=== ALL TESTS PASSED SUCCESSFULLY! ===")

if __name__ == '__main__':
    run_tests()
