# Barber POS & Kiosk System (Flutter)

An *offline-first, multi-tenant barbershop POS and kiosk system* built with Flutter.  
Designed for real-world use with employee time tracking, transactions, reporting, and reliable cloud synchronization.

The system works fully offline using SQLite and automatically syncs data when connectivity is available.

---

## Core Features

### Offline-First Architecture
- Fully functional without internet
- Local persistence using SQLite
- Automatic sync when connectivity is restored
- Manual sync controls available for reliability

---

## Authentication & Shops

### Authentication
- Email/password authentication (Supabase)
- Input validation for email and password
- Secure session handling with login/logout support

### Multi-Shop Support
- Users can manage *multiple shops*
- On login:
  - Select an existing shop
  - Or create a new shop
- Each shop includes:
  - Shop name
  - Admin password (required for admin-only actions)

### Shop Context Handling
- Selected shop_id is:
  - Stored in app state (in-memory)
  - Persisted locally (SharedPreferences)
- All operations are strictly scoped to the active shop
- Prevents cross-shop data access or leakage

---

## Admin Management

### Employees
- Create employees with:
  - Name
  - 5-digit passcode (kiosk-friendly)
- Employees are *preserved for historical integrity*
- Validations prevent invalid or duplicate entries

### Products & Cuts(Services)
- Manage products sold in-shop
- Manage services (e.g. haircut, shave)
- Prices stored as decimals
- Items are preserved for reporting and historical data

---

## Employee Time Tracking
- Clock in / clock out using passcode
- One clock-in and one clock-out per day (validated)
- Automatic recovery:
  - If an employee forgets to clock out, the next clock-in safely closes the previous shift
- All timestamps stored in *UTC* to avoid timezone issues

---

## Transactions (POS Flow)
- Employee selection
- Add multiple:
  - Services
  - Products
- Supports:
  - Tips
  - Discounts (amount-based)
  - Payment method (Cash / Card)
- Transactions stored locally and synced automatically

---

## Reporting
- Financial reports including:
  - Total sales
  - Tips
  - Discounts
  - Payment method breakdown
- Local device stores approximately *60 days* of transactional data
- Older data remains accessible from the cloud
- Automatic pruning to control device storage usage

---

## Cloud Sync Strategy

### Sync Metadata
Each table includes:
- shop_id
- created_at
- last_synced_at

### Automatic Sync
- On app launch:
  - Connectivity is checked automatically
  - Pending changes are synced if internet is available
- On every data change:
  - App attempts immediate upload
  - On success, last_synced_at is updated

### Sync Rules
- last_synced_at == null → upload
- last_synced_at != null → skip upload

This prevents:
- Duplicate uploads
- Unnecessary network usage
- Data conflicts

### Manual Sync Controls
- Manual refresh/upload buttons available per feature (e.g. employees, products)
- Allows recovery if automatic sync was interrupted

---

## Device Change / Reinstallation
- On login:
  - Downloads core shop data (employees, products, services)
- Reports:
  - Only last 60 days downloaded locally
- Cloud remains the source of truth for historical data

---

## Tech Stack
- Flutter (Dart)
- SQLite (offline storage)
- Supabase (authentication & cloud database)
- Android kiosk/tablet optimized UI

---

## Notes
- Designed with production constraints in mind:
  - Offline reliability
  - Data integrity
  - Multi-tenant security
- Secrets and production configuration are not committed

---

## License
Private / Portfolio project
