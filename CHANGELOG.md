# BraeNova StockMaster POS - Recent Updates Documentation

This document outlines all major architectural changes, UI/UX improvements, and new features built into the system during the recent development sprint.

## 1. Offline POS Architecture (PWA & Background Sync)
**Objective**: Allow cashiers to continue selling without interruption even if the internet connection completely drops.
- **Service Worker (`sw.js`)**: Upgraded to use a **Network-First caching strategy**. The Service Worker intercepts all web traffic. When a cashier navigates to the POS, it fetches the live page and simultaneously saves a clone of that HTML to the browser's hidden cache. If the device loses internet connection, the Service Worker automatically catches the failure and serves the cached interface instead of displaying a standard browser error.
- **Reload Prevention**: Previously, the POS functioned by refreshing the entire browser tab after every sale. This was replaced with a dynamic Javascript function (`resetPOS()`) that clears the cart, resets inputs, and retains the user on the same screen, ensuring continuous operation regardless of connection status.
- **Offline Transaction Queue**: When a sale is confirmed, the JS checks `navigator.onLine`. If offline, the sale payload is pushed into an array called `offlineQueue` inside the browser's `localStorage`. The system simulates a success by decrementing the local stock counts purely on the client side.
- **Auto-Sync Watcher**: A background interval (`syncOfflineQueue`) runs every 15 seconds. If it detects an active internet connection and items exist in the queue, it silently posts them to the `/api/checkout` endpoint. A floating badge dynamically updates the user on the sync progress.

## 2. Notice Board & Messaging System Overhaul
**Objective**: Improve the admin-to-cashier notification system with better formatting, attachments, and cleaner UI.
- **Duplicate Clean-up**: Manual database intervention was performed to delete duplicate notices stored in the Supabase table.
- **Local Timezone Formatting**: Timestamps sent from the backend in UTC are now intercepted by a Javascript parser on the frontend, calculating the user's exact local timezone, and formatting it precisely as `May-27-2026 | 03:10pm`.
- **Dismissible Notices**: Cashiers can now delete notices from their view. When the trash icon is clicked, the specific notice ID is saved to a `dismissed_notices` array in `localStorage`, effectively hiding it from the DOM permanently for that specific browser.
- **Smart Notification Dot**: The red alert bell dot was upgraded. When the notice modal is opened, the system writes the visible notice IDs to a `viewed_notices` array in `localStorage`. Upon page load, Javascript cross-references all loaded notices against the viewed list. If all notices have been viewed, the red dot is automatically suppressed.

## 3. PDF Attachment Engine
**Objective**: Allow the Super Admin to append PDF documents to notices.
- **Database Schema Alteration**: An `ALTER TABLE` SQL command was executed against the Supabase `notices` table to append a new column: `attachment_url (text)`.
- **Backend Routing (`app.py`)**: The `/superadmin/notice` POST route was updated to capture `request.files['attachment']`. The file is securely saved directly to the server's `static/uploads/notices/` directory.
- **Clean URLs**: To maintain a professional aesthetic, timestamp prefixes were removed from the uploaded file names. A custom wildcard route (`@app.route('/<filename>')`) was engineered in Flask. If a user navigates to `domain.com/filename.pdf`, Flask intercepts the request, validates the `.pdf` extension, and securely serves the file from the internal uploads directory without exposing the directory path structure.
- **UI Integration**: Modals in both the Dashboard and POS were updated to conditionally render a `[View Attachment]` button if an `attachment_url` exists in the database record.

## 4. UI/UX & Aesthetic Polish
**Objective**: Deliver a premium, visually consistent experience across all devices.
- **Vector Icons Upgrade**: A script was executed across all 16 Jinja HTML templates to systematically hunt and strip all OS-dependent Unicode emojis (e.g., 🛒, ⚙️). They were replaced with crisp, globally consistent `Bootstrap Icons` (SVGs) utilizing the `bi bi-*` class mapping.
- **Logo Optimization**: Custom CSS overriding border attributes (`border: none`) and `border-radius: 0` was applied to the `.logo-img` class to eliminate the unwanted box surrounding the transparent PNG. The baseline height was also increased for better visibility.
- **Brand Typography Adjustment**: The `.brand` CSS grid gap was drastically reduced via a Python automation script, moving the "BraeNova" text noticeably closer to the logo.
- **WhatsApp Support Integration**: Added a dedicated WhatsApp connection button to the offcanvas `#rightMenu`. Implemented an advanced dynamic CSS block providing a smooth `.btn-whatsapp:hover` effect involving background color transitions, upward `transform: translateY(-2px)` lifts, and customized green box-shadows.
