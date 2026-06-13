import re

with open('app.py', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. DELETE /api/v1/inventory/<int:item_id>
inv_api = '''@app.route('/api/v1/inventory/<int:item_id>', methods=['PUT', 'DELETE'])
@jwt_required
def api_update_inventory(item_id):
    shop_id = request.user.get('shop_id')
    if request.user.get('role') == 'cashier':
        return jsonify({'success': False, 'message': 'Unauthorized'}), 403
        
    if request.method == 'DELETE':
        try:
            delete_inventory_item(item_id, shop_id)
            return jsonify({'success': True, 'message': 'Item deleted'})
        except Exception as e:
            return jsonify({'success': False, 'message': str(e)}), 500
            
    data = request.json'''
content = re.sub(r'''@app\.route\('/api/v1/inventory/<int:item_id>', methods=\['PUT'\]\)\n@jwt_required\ndef api_update_inventory\(item_id\):\n    shop_id = request\.user\.get\('shop_id'\)\n    if request\.user\.get\('role'\) == 'cashier':\n        return jsonify\(\{'success': False, 'message': 'Unauthorized'\}\), 403\n        \n    data = request\.json''', inv_api, content)

# 2. POST /api/v1/dinau and PUT /api/v1/dinau/<int:record_id>
dinau_api = '''@app.route('/api/v1/dinau', methods=['GET', 'POST'])
@jwt_required
def api_dinau():
    shop_id = request.user.get('shop_id')
    plan = request.user.get('plan', 'starter')
    if plan == 'starter':
        return jsonify({'success': False, 'message': 'Dinau not available on starter plan'}), 403
        
    if request.method == 'POST':
        data = request.json
        if not data or 'customer_name' not in data or 'amount' not in data:
            return jsonify({'success': False, 'message': 'Invalid data'}), 400
        try:
            from database import add_dinau_record
            add_dinau_record(data['customer_name'], data['amount'], shop_id, data.get('note', ''))
            return jsonify({'success': True, 'message': 'Store credit added'})
        except Exception as e:
            return jsonify({'success': False, 'message': str(e)}), 500
            
    dinau_records = get_all_dinau(shop_id)
    for record in dinau_records:
        if isinstance(record.get('record_date'), datetime):
            record['record_date'] = record['record_date'].isoformat()
            
    return jsonify({'success': True, 'data': dinau_records})

@app.route('/api/v1/dinau/<int:record_id>', methods=['PUT'])
@jwt_required
def api_update_dinau(record_id):
    shop_id = request.user.get('shop_id')
    data = request.json
    if not data or 'status' not in data:
        return jsonify({'success': False, 'message': 'Invalid data'}), 400
    try:
        from database import update_dinau_status
        update_dinau_status(record_id, data['status'], shop_id)
        return jsonify({'success': True, 'message': 'Dinau status updated'})
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500
'''

content = re.sub(r'''@app\.route\('/api/v1/dinau', methods=\['GET'\]\)\n@jwt_required\ndef api_dinau\(\):\n    shop_id = request\.user\.get\('shop_id'\)\n    plan = request\.user\.get\('plan', 'starter'\)\n    if plan == 'starter':\n        return jsonify\(\{'success': False, 'message': 'Dinau not available on starter plan'\}\), 403\n        \n    dinau_records = get_all_dinau\(shop_id\)\n    # Parse dates to string for JSON serialization\n    for record in dinau_records:\n        if isinstance\(record\.get\('record_date'\), datetime\):\n            record\['record_date'\] = record\['record_date'\]\.isoformat\(\)\n            \n    return jsonify\(\{'success': True, 'data': dinau_records\}\)''', dinau_api, content)


# 3. Modify GET /api/v1/warehouse to include logs
warehouse_api = '''@app.route('/api/v1/warehouse', methods=['GET', 'POST'])
@jwt_required
def api_warehouse():
    shop_id = request.user.get('shop_id')
    plan = request.user.get('plan', 'starter')
    
    if plan == 'starter':
        return jsonify({'success': False, 'message': 'Warehouse is a Pro feature.'}), 403
        
    if request.method == 'GET':
        from database import get_warehouse_inventory, get_warehouse_logs
        items = get_warehouse_inventory(shop_id)
        logs = get_warehouse_logs(shop_id)
        return jsonify({'success': True, 'data': items, 'logs': logs})'''

content = re.sub(r'''@app\.route\('/api/v1/warehouse', methods=\['GET', 'POST'\]\)\n@jwt_required\ndef api_warehouse\(\):\n    shop_id = request\.user\.get\('shop_id'\)\n    plan = request\.user\.get\('plan', 'starter'\)\n    \n    if plan == 'starter':\n        return jsonify\(\{'success': False, 'message': 'Warehouse is a Pro feature\.'\}\), 403\n        \n    if request\.method == 'GET':\n        from database import get_warehouse_inventory\n        items = get_warehouse_inventory\(shop_id\)\n        return jsonify\(\{'success': True, 'data': items\}\)''', warehouse_api, content)


# 4. PUT /api/v1/cashiers/<int:cashier_id>/reset
reset_api = '''@app.route('/api/v1/cashiers/<int:cashier_id>', methods=['DELETE'])
@jwt_required
def api_delete_cashier(cashier_id):
    shop_id = request.user.get('shop_id')
    if request.user.get('role') == 'cashier':
        return jsonify({'success': False, 'message': 'Unauthorized'}), 403
        
    delete_user(cashier_id, shop_id)
    return jsonify({'success': True, 'message': 'Cashier deleted'})

@app.route('/api/v1/cashiers/<int:cashier_id>/reset', methods=['PUT'])
@jwt_required
def api_reset_cashier_pwd(cashier_id):
    shop_id = request.user.get('shop_id')
    if request.user.get('role') == 'cashier':
        return jsonify({'success': False, 'message': 'Unauthorized'}), 403
        
    data = request.json
    if not data or 'password' not in data:
        return jsonify({'success': False, 'message': 'Password required'}), 400
        
    from werkzeug.security import generate_password_hash
    from database import reset_password
    try:
        pw_hash = generate_password_hash(data['password'])
        reset_password(cashier_id, pw_hash, shop_id)
        return jsonify({'success': True, 'message': 'Password reset successfully'})
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500
'''
content = re.sub(r'''@app\.route\('/api/v1/cashiers/<int:cashier_id>', methods=\['DELETE'\]\)\n@jwt_required\ndef api_delete_cashier\(cashier_id\):\n    shop_id = request\.user\.get\('shop_id'\)\n    if request\.user\.get\('role'\) == 'cashier':\n        return jsonify\(\{'success': False, 'message': 'Unauthorized'\}\), 403\n        \n    delete_user\(cashier_id, shop_id\)\n    return jsonify\(\{'success': True, 'message': 'Cashier deleted'\}\)''', reset_api, content)


# 5. POST /api/v1/auth/register
register_api = '''@app.route('/api/v1/auth/register', methods=['POST'])
def api_register():
    data = request.json
    if not data or 'shop_name' not in data or 'username' not in data or 'password' not in data:
        return jsonify({'success': False, 'message': 'Missing required fields'}), 400
        
    shop_name = data['shop_name']
    username = data['username']
    password = data['password']
    
    from werkzeug.security import generate_password_hash
    from database import register_shop_and_owner
    
    try:
        pw_hash = generate_password_hash(password)
        # Register on starter plan
        user = register_shop_and_owner(shop_name, username, pw_hash, 'starter', 'monthly')
        return jsonify({'success': True, 'message': 'Registration successful!'})
    except Exception as e:
        return jsonify({'success': False, 'message': f"Registration failed. Username may already exist. {e}"}), 400

@app.route('/<filename>')'''
content = re.sub(r'''@app\.route\('/<filename>'\)''', register_api, content)


with open('app.py', 'w', encoding='utf-8') as f:
    f.write(content)
print('Patched app.py')
