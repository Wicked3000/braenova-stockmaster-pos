# BraeNova StockMaster POS 📊🛒

**BraeNova StockMaster** is an advanced, multi-tenant Point of Sale (POS) and Inventory Management web application designed specifically to empower retail shops, wholesalers, and multi-location businesses. Built with high performance and offline resilience in mind, it provides real-time analytics, automated reporting, and comprehensive shop governance.

## 🚀 Key Features

### 1. Robust Point of Sale (POS) Engine
- **Lightning Fast Checkout**: Barcode scanner compatible interface with rapid product search.
- **Offline Reliability (PWA)**: Full offline transaction support. If internet drops, sales are securely queued in local storage and automatically background-synced to the server once the connection is restored.
- **Multiple Payment Types**: Supports Cash, Mobile Banking, Internet Banking, and Dinau (Store Credit).
- **Automated Receipt Generation**: Generates printable thermal receipts dynamically.

### 2. Intelligent Inventory Management
- **Centralized Stock Pool**: Real-time cross-location inventory visibility for owners with multiple shops.
- **Expiry & Threshold Tracking**: Automated alerts for low-stock items and expiration tracking.
- **Quick Adjustments**: Seamless stock-in and stock-out adjustments with full auditing.

### 3. Comprehensive Dinau (Credit) System
- **Customer Debt Tracking**: Securely track store credit given to specific customers (min K20.00).
- **Repayment Logging**: Log partial or full debt settlements directly from the dashboard.

### 4. Advanced Analytics & Reporting
- **Automated Daily Close**: Cashiers can securely close their shifts, automatically generating categorized daily financial reports.
- **Interactive Dashboards**: Live tracking of Gross Revenue, Net Profit margins, Peak Selling Hours, and Top Selling Products.
- **Historical Ledgers**: Deep-dive into historical sales logs with capabilities to purge old records.

### 5. Multi-Tenant Administration
- **Role-Based Access Control**: Strict segregation of duties across Super Admin, Owner, Manager, and Cashier roles.
- **Multi-Shop Governance**: Owners on upper-tier plans can create and effortlessly switch between distinct shop locations via a unified interface.
- **Global Notice Board**: Super Admins can push critical system alerts and PDF attachments directly to the dashboards of specific user groups.
- **Impersonation**: Super Admins can temporarily impersonate specific shops to diagnose issues or provide high-level support.

---

## 🛠️ Technology Stack

- **Backend**: Python 3.x, Flask
- **Database**: PostgreSQL hosted on [Supabase](https://supabase.com) (via `supabase-py`)
- **Frontend**: HTML5 (Jinja2 Templates), Vanilla JavaScript, CSS3
- **Styling**: Bootstrap 5, Bootstrap Icons (SVGs), Custom Glassmorphism UI
- **PWA**: Service Worker (`sw.js`) with Network-First caching strategy

---

## 📁 System Architecture

```text
BraeNova-StockMaster/
│
├── app.py                   # Main Flask application logic and API endpoints
├── database.py              # Supabase database abstraction layer and CRUD operations
├── requirements.txt         # Python dependency manifest
├── CHANGELOG.md             # Detailed log of architectural and feature updates
│
├── static/                  # Public assets
│   ├── sw.js                # Service Worker for Offline PWA support
│   ├── manifest.json        # Web app manifest for installation
│   └── uploads/             # Directory for notice PDF attachments & static imagery
│
└── templates/               # Jinja2 HTML Templates
    ├── dashboard.html       # Owner/Manager analytics dashboard
    ├── pos.html             # Point of Sale interface
    ├── inventory.html       # Single-shop inventory management
    ├── centralized_inventory.html # Multi-shop master inventory view
    ├── dinau.html           # Store credit tracking system
    ├── sales_log.html       # Historical transaction ledger
    ├── superadmin.html      # High-level system administration & billing
    └── login.html / register.html # Authentication flows
```

---

## 🔧 Local Development Setup

### 1. Prerequisites
Ensure you have the following installed:
- **Python 3.8+**
- **Git**

### 2. Environment Configuration
You must configure your Supabase connection strings. Create a `.env` file (or set environmental variables) with your specific Supabase credentials:
```env
SUPABASE_URL="https://your-project-id.supabase.co"
SUPABASE_KEY="your-anon-or-service-role-key"
```
*(Note: Do not commit `.env` to version control).*

### 3. Installation
Clone the repository and install the required dependencies:
```bash
git clone https://github.com/Wicked3000/braenova-stockmaster-pos.git
cd braenova-stockmaster-pos
pip install -r requirements.txt
```

### 4. Running the Application
Start the Flask development server:
```bash
python app.py
```
The system will be accessible locally at `http://127.0.0.1:5000/`.

---

## 🔒 Security & Access

- **Authentication**: All critical routes are shielded by robust `@login_required` and role-specific (`@superadmin_required`, `@owner_required`) Python decorators.
- **Data Isolation**: Supabase queries are strictly filtered by the active user's `shop_id` within `database.py` to ensure cross-tenant data privacy.
- **Session Management**: Secure server-side Flask sessions store encrypted identity tokens.

---

*Designed and engineered by BraeNova IT Solutions.*
