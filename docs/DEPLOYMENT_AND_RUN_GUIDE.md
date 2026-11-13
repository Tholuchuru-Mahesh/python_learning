# Deployment, Setup & Execution Guide
## Unified POS & Inventory Management Platform (Release 1)

---

### 1. Prerequisites

- **Node.js**: v18+ (tested with v24.19.0)
- **npm**: v9+ (tested with v11.17.0)
- **Flutter SDK**: v3.16+ (tested with Flutter 3.47.1)
- **Database**: PostgreSQL (Production) or local zero-config SQLite (Development)

---

### 2. Backend Setup (`pos/backend`)

#### Installation
```bash
cd backend
npm install
```

#### Database Configuration

##### Development Mode (Zero-Config Local Testing)
The backend comes pre-configured for instant zero-dependency execution using local SQLite:
```bash
# Push schema and generate Prisma client
npm run db:push

# Seed initial retail shop data (products, owner, staff, bills, expenses)
npm run seed
```

##### Production PostgreSQL Mode (PRD §9.2)
1. In `backend/.env`, set your PostgreSQL connection string:
   ```env
   DATABASE_URL="postgresql://username:password@localhost:5432/pos_db?schema=public"
   ```
2. Run database migrations:
   ```bash
   npm run db:migrate:pg
   ```
3. Generate Prisma client:
   ```bash
   npm run db:generate:pg
   ```

#### Starting the Backend
```bash
# Development mode with hot-reload:
npm run start:dev

# Or production build:
npm run build
npm run start:prod
```
The API server will listen on `http://localhost:3000`.

#### Running Automated Vitest Suite (9 Regression Tests)
```bash
npm run test
```

---

### 3. Frontend Setup (`pos/frontend`)

The frontend is a single cross-platform Flutter application supporting Android, Web, and Windows Desktop.

#### Installation
```bash
cd frontend
flutter pub get
```

#### Running on Web
```bash
flutter run -d chrome
```

#### Building Web for Production
```bash
flutter build web --no-pub
```
The optimized web distribution is generated in `frontend/build/web`.

#### Building Android APK
```bash
flutter build apk --debug
```
The compiled Android binary is generated in:
`frontend/build/app/outputs/flutter-apk/app-debug.apk` (162 MB).

To install on a connected Android phone or POS terminal:
```bash
flutter install
```

#### Building on Windows Desktop
To build native Windows binaries (`.exe`), ensure Microsoft Visual Studio 2022 with the **"Desktop development with C++"** workload is installed:
```bash
flutter build windows
```

#### Code Analysis & Automated Tests
```bash
# Lint analysis (Zero issues)
flutter analyze

# Widget & offline queue tests (4/4 passed)
flutter test
```

---

### 4. Offline Billing Operation (Release 1)

1. **Automatic Offline Buffering**:
   - If the backend is unreachable during counter checkout, the bill is automatically saved to the persistent local queue on disk.
   - Cashiers can continue creating bills without interruptions.
   - Each offline bill is assigned a unique local ID (`LOCAL-XXXX`) and an immutable UUID `idempotencyKey`.
2. **Crash & Restart Resilience**:
   - Pending bills are persisted to local storage (`SharedPreferences`) and survive application or device reboots. Zero bills are silently lost.
3. **Synchronization**:
   - Cashiers can view queue status via the **"Offline Queue"** button in the billing screen.
   - When network connectivity is restored, clicking **"Sync Pending Bills Now"** (or automatic sync) submits pending transactions.
   - The server's idempotency engine guarantees that retries never cause duplicate bills or duplicate stock deductions.
   - Bill statuses are explicitly tracked: `PENDING`, `SYNCING`, `SYNCED`, `FAILED`.

---

### 5. Thermal Receipt Printing

- **Supported Connection Method**: Standard 80mm roll format dispatched to the OS/browser print spooler.
- **Preview & Direct Print**: Cashiers can preview itemized lines, discounts, tax, and reprint banners, then click **"Print Receipt"** to print via connected USB/Network/Virtual thermal printers.
- **Reprint Indication**: Any reprinted receipt renders a prominent `*** REPRINT OF RECEIPT ***` watermark.

---

### 6. Default Seed Accounts

The database seed provides three pre-configured accounts demonstrating the PRD §4.1/4.2 permission model:

| Role | Username | Password | Granted Permissions | Description |
| :--- | :--- | :--- | :--- | :--- |
| **Shop Owner** | `owner` | `password123` | **Full Universal Access** | Owner account with full control; immutable and cannot be deleted or revoked. |
| **Cashier** | `cashier` | `password123` | `CREATE_BILLS`, `VIEW_PRODUCTS` | Fast billing, cart operations, receipt printing. Restricted from reports and settings. |
| **Inventory Clerk** | `inventory` | `password123` | `VIEW_PRODUCTS`, `ADD_EDIT_PRODUCTS`, `UPDATE_STOCK` | Product catalogue, stock adjustments with reasons, stock movement ledger. Restricted from billing and financial reports. |

---

### 7. Cost-Optimization Strategy for Production Deployment (PRD §9.2 & §9.4)

1. **Single Low-Cost VPS**: Deploy both NestJS API and PostgreSQL on a single small VPS (e.g. 2GB RAM / 1 vCPU at ~$5-10/month on Hetzner, Linode, or DigitalOcean).
2. **Reverse Proxy & Free TLS**: Use Caddy or Nginx with automated Let's Encrypt certificates.
3. **Database Maintenance**:
   - Automated daily database dumps via a cron job to encrypted off-server object storage.
   - Database indexes on `(shop_id, created_at)` and `(shop_id, status)` ensure high query throughput without needing expensive managed database instances.
4. **Static Frontend Hosting**:
   - Flutter Web build can be hosted on free static tiers (Cloudflare Pages, Netlify, or directly served via Nginx).
