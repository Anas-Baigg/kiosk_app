# Barber POS & Kiosk System (Flutter)

An offline-first, multi-tenant barbershop POS and kiosk system built with Flutter.  
Designed for real-world tablet use with employee time tracking, transactions, financial reporting, and cloud synchronisation.

---

## Tech Stack

| Layer             | Technology                                                        |
| ----------------- | ----------------------------------------------------------------- |
| Framework         | Flutter 3.x / Dart SDK ^3.8.1                                     |
| Local storage     | SQLite via `sqflite ^2.4.2`                                       |
| Cloud backend     | Supabase (PostgreSQL + Auth) via `supabase_flutter ^2.0.0`        |
| Admin security    | bcrypt password hashing via `bcrypt ^1.2.0`                       |
| Connectivity      | `connectivity_plus ^7.0.0`                                        |
| Local persistence | `shared_preferences ^2.2.0`                                       |
| Config            | `flutter_dotenv ^6.0.0` — credentials read from `.env` at runtime |

---

## Architecture

The app is **offline-first**: SQLite is the write-ahead source of truth for all user interactions. Supabase is the sync target and cloud backup, not the primary data store.

```
Auth (Supabase)
    ↓
Shop selection → AppState (static in-memory) + SharedPreferences
    ↓
SQLite (all reads/writes during normal use)
    ↓
SyncService → Supabase (push unsynced rows on connectivity)
```

**State management**: no library. `AppState` is a plain static class holding `shopId`, `shopName`, and `adminPasswordHash`. Feature pages use `StatefulWidget` + `FutureBuilder` with direct SQLite queries.

---

## Authentication

- **User login**: Supabase email/password (PKCE flow)
- **Admin access**: 5-digit numeric passcode, bcrypt-hashed and stored in SharedPreferences; brute-force protected (3-attempt limit, 60-second lockout)
- **Employee clock-in**: 5-digit numeric passcode stored as a plaintext integer in SQLite; no brute-force protection yet

---

## Multi-Shop Support

Each Supabase user can own or be associated with multiple shops. On login the user selects a shop; `shop_id` is written to `AppState` and persisted in SharedPreferences. Every SQLite table and every Supabase query is scoped by `shop_id`.

---

## Core Features

### Employee Time Tracking

- Clock in / clock out via passcode
- One open shift per day enforced
- Auto-recovery: if an employee forgets to clock out, the next clock-in safely closes the previous shift

### Transactions (POS Flow)

- Select clocked-in employee
- Add services (cuts) and products to cart
- Apply tip and discount (amount-based)
- Choose payment method: Cash or Card
- Saved atomically to SQLite (header + items in one transaction)

### Reporting

- Financial summary: totals, tips, discounts, payment breakdown
- Time log history
- Till balance per day
- Date-range picker for all report types

### Admin Management

- CRUD for employees, services (cuts), and products
- Items are deactivated rather than deleted (historical integrity)
- Generic `ManagementListPage` widget handles all three entity types
- Edit dialogs use inline field validation with success checkmark; employee passcode field is obscured with "leave blank to keep current" on update

---

## Cloud Sync

### Sync Metadata

Every SQLite table has `shop_id`, `created_at`, and `last_synced_at`.

- `last_synced_at IS NULL` → record is pending upload
- `last_synced_at IS NOT NULL` → already uploaded, skip

### Automatic Sync

`SyncService` monitors connectivity. When internet is restored a 2-second debounced trigger calls the sync pipeline. `syncAll()` calls internal sync methods directly (bypassing their individual `_isSyncing` guards), so auto-sync on connectivity restore correctly uploads pending rows.

### Realtime Sync

`RealtimeService` maintains a Supabase Realtime websocket channel for the active shop. Changes made from the Supabase dashboard (or another device) to `employee`, `cuts`, `products`, and `till_balance` are received instantly and written to SQLite without requiring a manual refresh. The channel subscribes when a shop is selected, re-subscribes after connectivity is restored (with a catch-up pull for changes missed while offline), and unsubscribes on logout. `time_logs` are excluded — clock corrections appear on the next report load.

### Connectivity Banner

A slim animated banner appears at the top of every screen when the device is offline (amber) or the last sync failed (red, tap to retry). It disappears automatically when connectivity is restored and sync succeeds.

### Data Retention

- On fresh install / device change: full reference data (employees, cuts, products) is downloaded; last **30 days** of transactions, time logs, and till balance are pulled down
- Purge job deletes synced records older than **30 days** to control local storage
- Data older than 30 days remains in Supabase and is accessible via reports if re-downloaded

### Conflict Resolution

During a pull, rows that already exist locally with `last_synced_at IS NULL` (unsynced local changes) are skipped, preserving local-first behaviour.

---

## Credentials & Security Notes

- Supabase credentials are stored in `.env` at the project root, which is excluded from version control via `.gitignore`
- `.env` is listed as a Flutter asset in `pubspec.yaml`, so it is **compiled into the app binary** — credentials are extractable from the APK
- For Supabase ANON keys, client-side exposure is by design; actual data security depends on Row Level Security (RLS) policies configured in the Supabase dashboard (not part of this repository)
- Employee passcodes are stored as plaintext integers in SQLite; only the admin passcode uses bcrypt
- Admin passcode entry has brute-force protection (3 attempts, 60-second lockout); employee clock-in does not yet

---

## Project Status

This is a private portfolio project, not yet production-hardened.

**Implemented and working:**

- Offline-first SQLite with automatic push-sync to Supabase on connectivity restore
- Supabase Realtime live sync for reference data (employees, cuts, products, till balance)
- Connectivity banner with offline/sync-failed states
- Admin passcode with bcrypt hashing and brute-force protection (3 attempts, 60 s lockout)
- Atomic transaction saving, performance indexes, 30-day data retention with purge
- Consistent dialog UX throughout (inline validation, success checkmark states)

---

## License

Private / Portfolio project
