# StockSweep: Canteen & Tuck Shop Edition
## Project Overview
StockSweep is a localized, mobile-first inventory management system designed specifically for the MSME sector in Papua New Guinea. This version is tailored for **Canteens and Tuck Shops** to prevent stockouts of essential goods (e.g., 1kg Rice, Ox & Palm, Noodles) and automate daily sales reconciliation.

## 🛠 Tech Stack (The "Antigravity" Stack)
* **Intelligence:** Google Antigravity (Agentic Development)
* **Backend:** Python (Flask/FastAPI)
* **Frontend:** Bootstrap 5 (Mobile-First, High Contrast)
* **Database:** Supabase (PostgreSQL + Real-time)
* **Notifications:** Telegram Bot API / WhatsApp Business API

## 🚀 Core Features for the PNG Market
1.  **Low-Stock Alerts:** Automated notifications sent via Telegram/WhatsApp when essential items hit a minimum threshold.
2.  **One-Tap Sales:** A simplified Bootstrap interface designed for rapid entry during busy morning/lunch rushes.
3.  **End-of-Day "Dinau" Tracker:** A module to track store credit (Dinau) with simple "Owed" vs "Paid" status.
4.  **Cash-to-Stock Reconciliation:** Python logic that calculates expected daily revenue based on inventory movement to reduce internal theft.
5.  **Offline-Ready:** Built to handle PNG's intermittent connectivity by caching state and syncing when 4G/LTE is stable.

## 💰 Monetization Model
* **Phase 1:** One-time Setup Fee (K250 - K500) — Includes hardware configuration and initial stock entry.
* **Phase 2:** Monthly Support/Cloud Fee (K15 - K25) — Covers Supabase hosting and data backups.
* **Phase 3:** Feature Add-ons — Extra charge for multi-shop sync or advanced reporting.

## 🤖 Antigravity Mission Workflow
### Mission 1: Database Schema (Supabase)
* **Task:** Create `inventory`, `sales`, and `dinau_records` tables.
* **Agent Prompt:** "Design a Supabase schema for a PNG tuck shop. Include a `min_threshold` column in `inventory` and a `status` (paid/unpaid) in `dinau_records`."

### Mission 2: Frontend (Bootstrap 5)
* **Task:** Build a high-contrast, thumb-friendly UI.
* **Agent Prompt:** "Create a Bootstrap 5 layout. Ensure buttons for 'Rice', 'Tinned Fish', and 'Noodles' are at least 60px tall for easy mobile tapping. Use a dark theme to save battery."

### Mission 3: Logic & Alerts (Python)
* **Task:** Implement the trigger logic.
* **Agent Prompt:** "Write a Python script that monitors Supabase real-time updates. If `quantity` < `min_threshold`, send a Telegram alert to the owner with the item name and remaining count."

## 📱 Mobile Compatibility Rules
* **Rule 1:** Zero horizontal scrolling on 360px width devices.
* **Rule 2:** All critical actions (Sale/Restock) must be reachable within one thumb-tap.
* **Rule 3:** Optimize image sizes for PNG's data costs (use SVGs where possible).

---
*Developed by Joel Namuri | Web & System Developer, PNG*
