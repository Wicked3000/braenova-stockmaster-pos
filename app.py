import os
from flask import Flask, render_template, request, redirect, url_for, session, flash, jsonify
from functools import wraps
from werkzeug.utils import secure_filename
from database import (
    verify_user, get_all_inventory, get_all_categories, 
    add_sale, get_sales_history, get_sales_summary, get_inventory_status, 
    get_inventory_financials, get_all_cashiers, add_user,
    reset_password, delete_user, update_inventory_quick, update_inventory_item,
    delete_inventory_item, get_all_dinau, update_dinau_status,
    get_daily_sales_chart, get_hourly_sales_today, get_category_sales_distribution,
    get_expired_items, add_inventory_item, add_category, get_cashier_summary,
    close_shop, get_all_reports, add_dinau_record, cleanup_old_sales, register_shop_and_owner,
    get_all_shops, toggle_shop_status
)

app = Flask(__name__)
app.secret_key = 'braenova_stockmaster_secret_key'
app.config['UPLOAD_FOLDER'] = 'static/uploads'
os.makedirs(app.config['UPLOAD_FOLDER'], exist_ok=True)

# Custom Filter for Currency
@app.template_filter('kina')
def kina_filter(val):
    if val is None: return "K0.00"
    return f"K{float(val):.2f}"

# RBAC Decorators
def login_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if 'user_id' not in session or 'shop_id' not in session:
            session.clear()
            return redirect(url_for('login'))
        return f(*args, **kwargs)
    return decorated_function

def owner_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if session.get('role') not in ['owner', 'superadmin']:
            flash("Unauthorized Access: Owners Only", "error")
            return redirect(url_for('pos'))
        return f(*args, **kwargs)
    return decorated_function

def superadmin_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if session.get('role') != 'superadmin':
            flash("Unauthorized Access", "error")
            return redirect(url_for('dashboard'))
        return f(*args, **kwargs)
    return decorated_function

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        user = verify_user(request.form['username'], request.form['password'])
        if user == "suspended":
            flash("Your shop account is currently suspended. Please contact support.", "error")
            return redirect(url_for('login'))
        elif user:
            session['user_id'] = user['id']
            session['username'] = user['username']
            session['role'] = user['role']
            session['shop_id'] = user['shop_id']
            
            if user['role'] == 'superadmin':
                return redirect(url_for('superadmin_dashboard'))
            if user['role'] == 'cashier':
                return redirect(url_for('pos'))
            return redirect(url_for('dashboard'))
        flash("Invalid Credentials", "error")
    return render_template('login.html')

@app.route('/logout')
def logout():
    session.clear()
    return redirect(url_for('login'))

# --- PUBLIC & ONBOARDING ROUTES ---

@app.route('/')
def landing():
    if 'user_id' in session:
        if 'shop_id' not in session:
            session.clear()
            return render_template('landing.html')
            
        if session.get('role') == 'cashier':
            return redirect(url_for('pos'))
        return redirect(url_for('dashboard'))
    return render_template('landing.html')

@app.route('/register', methods=['GET', 'POST'])
def register():
    if request.method == 'POST':
        shop_name = request.form['shop_name']
        username = request.form['username']
        password = request.form['password']
        
        from werkzeug.security import generate_password_hash
        from database import register_shop_and_owner
        
        try:
            password_hash = generate_password_hash(password)
            user = register_shop_and_owner(shop_name, username, password_hash)
            
            # Auto-login after registration
            session['user_id'] = user['id']
            session['username'] = user['username']
            session['role'] = user['role']
            session['shop_id'] = user['shop_id']
            
            flash("Shop registered successfully! Welcome to StockMaster.", "success")
            return redirect(url_for('dashboard'))
        except Exception as e:
            # Simple error handling for duplicate username
            flash("Registration failed. That username may already be taken.", "error")
            
    return render_template('register.html')

# --- SUPERADMIN ROUTES ---

@app.route('/superadmin')
@login_required
@superadmin_required
def superadmin_dashboard():
    shops = get_all_shops()
    return render_template('superadmin.html', shops=shops)

@app.route('/superadmin/toggle', methods=['POST'])
@login_required
@superadmin_required
def toggle_shop():
    shop_id = request.form.get('shop_id')
    status = request.form.get('status') == 'true'
    toggle_shop_status(shop_id, status)
    flash(f"Shop status updated successfully.", "success")
    return redirect(url_for('superadmin_dashboard'))

# --- OWNER ONLY ROUTES ---

@app.route('/dashboard')
@login_required
def dashboard():
    shop_id = session.get('shop_id')
    if session.get('role') == 'owner':
        summary = get_sales_summary(shop_id)
        profit = summary['total_profit']
    else:
        summary = get_cashier_summary(session.get('user_id'), shop_id)
        profit = None
        
    expiry_alerts = get_expired_items(shop_id)
    inventory_status = get_inventory_status(shop_id)
    chart_data = get_daily_sales_chart(shop_id)
    hourly_data = get_hourly_sales_today(shop_id)
    cat_dist = get_category_sales_distribution(shop_id)
    
    total_alerts = len(expiry_alerts) + inventory_status['needs_restock']
    
    return render_template('dashboard.html', 
                           summary=summary, 
                           profit=profit,
                           expired_items=expiry_alerts,
                           low_stock_count=inventory_status['needs_restock'],
                           total_alerts=total_alerts,
                           chart_data=chart_data,
                           hourly_data=hourly_data,
                           cat_dist=cat_dist)

@app.route('/sales-log')
@login_required
@owner_required
def sales_log():
    logs = get_sales_history(session.get('shop_id'))
    return render_template('sales_log.html', history=logs)

@app.route('/reports')
@login_required
@owner_required
def daily_reports_history():
    from database import get_all_reports
    history = get_all_reports(session.get('shop_id'))
    return render_template('reports.html', history=history)

# --- SHARED/CASHIER ACCESSIBLE ROUTES ---

@app.route('/pos')
@login_required
def pos():
    inventory = get_all_inventory(session.get('shop_id'))
    categories = get_all_categories(session.get('shop_id'))
    return render_template('pos.html', inventory=inventory, categories=categories)

@app.route('/inventory')
@login_required
def inventory_mgmt():
    shop_id = session.get('shop_id')
    inventory = get_all_inventory(shop_id)
    categories = get_all_categories(shop_id)
    financials = get_inventory_financials(shop_id)
    cashiers = get_all_cashiers(shop_id) if session.get('role') == 'owner' else []
    return render_template('inventory.html', inventory=inventory, categories=categories, financials=financials, cashiers=cashiers)

@app.route('/dinau')
@login_required
def dinau_mgmt():
    list_items = get_all_dinau(session.get('shop_id'))
    return render_template('dinau.html', dinau=list_items)

# --- API & ACTIONS ---

@app.route('/api/checkout', methods=['POST'])
@login_required
def checkout():
    try:
        data = request.json
        items = data.get('items', [])
        payment_method = data.get('payment_method', 'cash')
        customer_name = data.get('customer_name')
        
        if not items:
            return jsonify({'success': False, 'message': 'Cart is empty'}), 400

        total_transaction_amount = sum(float(i['total_price']) for i in items)
        if payment_method == 'dinau' and total_transaction_amount < 20.00:
            return jsonify({'success': False, 'message': 'Minimum K20.00 required for credit sales.'}), 400

        import uuid
        receipt_id = str(uuid.uuid4())[:8].upper()

        for item in items:
            add_sale(
                inventory_id=item['id'],
                qty_sold=item['qty'],
                total_price=item['total_price'],
                shop_id=session.get('shop_id'),
                cashier_id=session.get('user_id'),
                is_dinau=(payment_method == 'dinau'),
                customer_name=customer_name,
                payment_method=payment_method,
                receipt_id=receipt_id
            )
        
        # Automatically purge sales records older than 30 days
        cleanup_old_sales(session.get('shop_id'))

        # If it's a credit (dinau) sale, record the total debt once
        if payment_method == 'dinau' and customer_name:
            add_dinau_record(customer_name, total_transaction_amount, session.get('shop_id'))
        
        return jsonify({'success': True})
            
    except Exception as e:
        print(f"Checkout error: {str(e)}")
        return jsonify({'success': False, 'message': f'Server Error: {str(e)}'}), 500

@app.route('/api/dinau/status', methods=['POST'])
@login_required
def update_debt_status():
    record_id = request.form.get('record_id')
    status = request.form.get('status', 'paid')
    if record_id:
        update_dinau_status(record_id, status, session.get('shop_id'))
        flash(f"Debt marked as {status.upper()}", "success")
    return redirect(url_for('dinau_mgmt'))

@app.route('/inventory/quick-update', methods=['POST'])
@login_required
def quick_update():
    try:
        item_id = request.form.get('item_id')
        qty_add = int(request.form.get('qty_add', 0))
        new_price = float(request.form.get('new_price'))
        cost_price = float(request.form.get('cost_price'))
        update_inventory_quick(item_id, qty_add, new_price, cost_price, session.get('shop_id'))
        flash('Inventory updated successfully!', 'success')
    except Exception as e:
        flash(f'Update failed: {str(e)}', 'error')
    return redirect(url_for('inventory_mgmt'))

@app.route('/inventory/add', methods=['POST'])
@owner_required
def add_product():
    try:
        name = request.form.get('item_name')
        qty = int(request.form.get('quantity'))
        threshold = int(request.form.get('threshold'))
        cost = float(request.form.get('cost'))
        price = float(request.form.get('price'))
        category = request.form.get('category')
        expiry = request.form.get('expiry_date')
        
        image_url = None
        if 'image' in request.files:
            file = request.files['image']
            if file and file.filename != '':
                import uuid
                from database import supabase
                filename = f"{uuid.uuid4().hex}_{secure_filename(file.filename)}"
                supabase.storage.from_("products").upload(
                    path=filename,
                    file=file.read(),
                    file_options={"content-type": file.content_type}
                )
                image_url = supabase.storage.from_("products").get_public_url(filename)

        add_inventory_item(name, qty, threshold, price, session.get('shop_id'), cost, category, image_url, expiry)
        flash('New product added!', 'success')
    except Exception as e:
        flash(f'Error adding product: {str(e)}', 'error')
    return redirect(url_for('inventory_mgmt'))

@app.route('/category/add', methods=['POST'])
@owner_required
def add_new_category():
    name = request.form.get('category_name')
    if name:
        add_category(name, session.get('shop_id'))
        flash('Category added!', 'success')
    return redirect(url_for('inventory_mgmt'))

@app.route('/category/delete/<int:cat_id>')
@owner_required
def delete_category_route(cat_id):
    try:
        from database import delete_category
        delete_category(cat_id, session.get('shop_id'))
        flash('Category removed!', 'success')
    except Exception as e:
        flash(f'Error: {str(e)}', 'error')
    return redirect(url_for('inventory_mgmt'))

@app.route('/inventory/update', methods=['POST'])
@owner_required
def update_product():
    try:
        item_id = request.form.get('id')
        item_name = request.form.get('item_name')
        category = request.form.get('category')
        quantity = int(request.form.get('quantity'))
        threshold = int(request.form.get('threshold'))
        cost = float(request.form.get('cost'))
        price = float(request.form.get('price'))
        expiry_date = request.form.get('expiry_date')
        
        image_url = None
        if 'image' in request.files:
            file = request.files['image']
            if file and file.filename != '':
                import uuid
                from database import supabase
                filename = f"{item_id}_{uuid.uuid4().hex}_{secure_filename(file.filename)}"
                supabase.storage.from_("products").upload(
                    path=filename,
                    file=file.read(),
                    file_options={"content-type": file.content_type}
                )
                image_url = supabase.storage.from_("products").get_public_url(filename)

        update_inventory_item(item_id, session.get('shop_id'), item_name, quantity, threshold, price, cost, category, image_url, expiry_date)
        flash('Product updated successfully!', 'success')
    except Exception as e:
        flash(f'Error updating product: {str(e)}', 'error')
    return redirect(url_for('inventory_mgmt'))

@app.route('/inventory/delete/<int:item_id>')
@owner_required
def delete_item(item_id):
    delete_inventory_item(item_id, session.get('shop_id'))
    flash("Item deleted successfully", "success")
    return redirect(url_for('inventory_mgmt'))

@app.route('/users/add', methods=['POST'])
@owner_required
def create_user():
    data = request.form
    from werkzeug.security import generate_password_hash
    password_hash = generate_password_hash(data['password'])
    add_user(data['username'], password_hash, shop_id=session.get('shop_id'))
    flash("Cashier registered successfully!", "success")
    return redirect(url_for('inventory_mgmt'))

@app.route('/users/reset', methods=['POST'])
@owner_required
def reset_pw():
    data = request.form
    from werkzeug.security import generate_password_hash
    password_hash = generate_password_hash(data['new_password'])
    reset_password(data['user_id'], password_hash, session.get('shop_id'))
    flash("Password reset successfully!", "success")
    return redirect(url_for('inventory_mgmt'))

@app.route('/users/delete', methods=['POST'])
@owner_required
def remove_user():
    user_id = request.form.get('user_id')
    delete_user(user_id, session.get('shop_id'))
    flash("User removed successfully.", "success")
    return redirect(url_for('inventory_mgmt'))

@app.route('/api/inventory')
@login_required
def get_inventory_api():
    inventory = get_all_inventory(session.get('shop_id'))
    return jsonify(inventory)

@app.route('/reports/close', methods=['POST'])
@owner_required
def close_report():
    actual_cash = float(request.form.get('actual_cash', 0))
    restock_notes = request.form.get('restock_notes', '')
    summary = get_sales_summary(session.get('shop_id'))
    close_shop(actual_cash, summary['expected_cash'], session.get('shop_id'), summary['total_sales'], summary['total_profit'], restock_notes)
    flash("Shop closed. Daily report generated!", "success")
    return redirect(url_for('dashboard'))

@app.route('/sales-log/purge', methods=['POST'])
@owner_required
def purge_sales():
    try:
        from database import cleanup_old_sales
        cleanup_old_sales(session.get('shop_id'))
        flash("Old sales records (30+ days) have been cleared.", "success")
    except Exception as e:
        flash(f"Purge failed: {e}", "error")
    return redirect(url_for('sales_log'))

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000, threaded=True)
