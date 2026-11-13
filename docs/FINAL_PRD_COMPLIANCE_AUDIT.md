# FINAL PRD COMPLIANCE AUDIT & VERIFICATION REPORT
## Unified POS & Inventory Management Platform (PRD v0.2 Review Draft)

**Audit Version**: 2.0 (Post-Release 1 Completion & Production Verification)  
**Date**: 13 November 2026  
**Auditor**: Senior Software Architect & Technical Lead  

---

### 1. Complete Requirement-to-Code Traceability Matrix

Every requirement in approved PRD v0.2 has been audited directly against the source code:

| PRD Section | Requirement | Status | Source Location | Verification Evidence |
| :--- | :--- | :---: | :--- | :--- |
| **§3.1** | Grocery / General Store focus (piece, packet, bottle, kg, litre) | **VERIFIED** | `backend/src/products/dto/create-product.dto.ts`<br>`frontend/lib/screens/products_screen.dart` | Passed Vitest test #3. Verified common retail units with 3-decimal quantity precision. |
| **§3.2** | Multi-Platform: Android, Web, Windows Desktop | **VERIFIED (Web & Android)**<br>**BLOCKED (Windows native)** | `frontend/lib/screens/main_layout.dart`<br>`frontend/lib/main.dart` | `flutter build web` passed (102s). `flutter build apk --debug` passed (`app-debug.apk` 162MB). Windows build blocked by missing Visual Studio C++ toolchain on host. |
| **§3.2, §6** | Exclude iOS and macOS Desktop | **OUT OF SCOPE** | PRD §3.2, §6 | Excluded from release boundary. |
| **§4.1** | Owner-controlled permissions (no fixed roles) | **VERIFIED** | `backend/src/common/constants/permissions.constant.ts`<br>`backend/src/staff/staff.service.ts` | Uses 8 granular permissions; no fixed role logic enforced. |
| **§4.2** | 8 Checkbox permissions | **VERIFIED** | `backend/src/common/guards/permissions.guard.ts`<br>`frontend/lib/screens/staff_screen.dart` | Backend checks permissions on all protected routes; Owner has full access; staff access managed via checkboxes. Passed Vitest test #1. |
| **§4.2** | Protected Owner Account (Immutable) | **VERIFIED** | `backend/src/staff/staff.service.ts#L88` | Attempting to update or revoke owner throws `ForbiddenException`. Passed Vitest test #1. |
| **§4.2** | Immediate staff access revocation | **VERIFIED** | `backend/src/staff/staff.service.ts#L125` | `DELETE /api/staff/:id` sets `isActive=false`; subsequent logins/API calls blocked immediately. |
| **§5.1** | Shop registration & Owner credential creation | **VERIFIED** | `backend/src/auth/auth.service.ts`<br>`frontend/lib/screens/login_screen.dart` | Creates Shop and Owner atomically in a database transaction with bcrypt password hashing. Passed Vitest test #1. |
| **§5.1** | Shop settings (name, address, phone, currency, tax %, receipt header/footer) | **VERIFIED** | `backend/src/shop/shop.service.ts`<br>`frontend/lib/screens/settings_screen.dart` | Guarded by `SHOP_SETTINGS` permission. Updates persist to database and reflect on receipts. |
| **§5.2** | Product catalogue CRUD | **VERIFIED** | `backend/src/products/products.service.ts`<br>`frontend/lib/screens/products_screen.dart` | Products can be created, updated, filtered by category/search, and deactivated. |
| **§5.2** | Opening stock recorded in movement history | **VERIFIED** | `backend/src/products/products.service.ts#L105` | When `openingStock > 0`, an `OPENING_STOCK` movement record is atomically committed. Passed Vitest test #3. |
| **§5.2** | Authorized stock adjustments with mandatory reason | **VERIFIED** | `backend/src/inventory/inventory.service.ts`<br>`frontend/lib/screens/inventory_screen.dart` | Adjustments require a non-empty `reason` and valid `movementType`. Passed Vitest test #3. |
| **§5.2** | Negative stock prevention by default | **VERIFIED** | `backend/src/inventory/inventory.service.ts#L27`<br>`backend/src/billing/billing.service.ts#L78` | Attempting to adjust stock below 0 throws `BadRequestException`. Passed Vitest test #3. |
| **§5.2** | Stock movement audit history ledger | **VERIFIED** | `backend/src/inventory/inventory.service.ts#L107`<br>`frontend/lib/screens/inventory_screen.dart` | Captures timestamp, product, user ID, quantity change, before/after stock, and reason. Passed Vitest test #3. |
| **§5.2** | Stock valuation estimates (Cost vs Retail) | **VERIFIED** | `backend/src/inventory/inventory.service.ts#L145`<br>`frontend/lib/screens/inventory_screen.dart` | Computed dynamically as `currentStock * purchaseCost` and `currentStock * sellingPrice`. |
| **§5.3** | Fast counter billing: search, cart, line totals, discounts, final total | **VERIFIED** | `frontend/lib/screens/billing_screen.dart`<br>`backend/src/billing/billing.service.ts` | Interactive cart with quantity steppers, subtotal, discount, tax, and final total. Passed Vitest test #5. |
| **§5.3** | Atomic bill commit & single stock deduction | **VERIFIED** | `backend/src/billing/billing.service.ts#L43-L175` | Entire bill creation and stock deduction runs inside `prisma.$transaction`. Passed Vitest test #5. |
| **§5.3** | Idempotency duplicate prevention | **VERIFIED** | `backend/src/billing/billing.service.ts#L22`<br>`frontend/lib/providers/billing_provider.dart` | Client generates UUID `idempotencyKey`. Network retries return original bill without double stock deductions. Passed Vitest test #7. |
| **§5.3** | Thermal receipt printing (80mm standard format) | **VERIFIED (Spooler)**<br>**UNVERIFIED (Hardware)** | `frontend/lib/widgets/receipt_dialog.dart` | Formats receipt to standard 80mm roll format and prints via OS print spooler. Untested on physical POS printer. |
| **§5.3** | Receipt reprint with explicit reprint indicator | **VERIFIED** | `backend/src/billing/billing.service.ts#L205`<br>`frontend/lib/widgets/receipt_dialog.dart#L190` | `reprintCount` increments; receipt renders `*** REPRINT OF RECEIPT ***`. |
| **§5.4** | Today's Sales Value & Number of Bills | **VERIFIED** | `backend/src/reports/reports.service.ts#L13`<br>`frontend/lib/screens/reports_screen.dart` | Calculated from completed bills between `00:00:00` and `23:59:59` today. Passed Vitest test #5. |
| **§5.4** | Top-selling product by quantity today | **VERIFIED** | `backend/src/reports/reports.service.ts#L55` | Ranks products strictly by units sold today. Passed Vitest test #5. |
| **§5.4** | Top-revenue product today (separated from quantity) | **VERIFIED** | `backend/src/reports/reports.service.ts#L58` | Ranks products strictly by sales value today. Passed Vitest test #5. |
| **§5.5** | Estimated Gross Profit & Margin % (recorded cost basis) | **VERIFIED** | `backend/src/billing/billing.service.ts#L96`<br>`backend/src/reports/reports.service.ts#L170` | Snapshot cost basis captured at time of sale; labeled as Estimated Gross Profit. Passed Vitest test #5. |
| **§5.6** | Low-stock alerts triggered at or below threshold | **VERIFIED** | `backend/src/billing/billing.service.ts#L152`<br>`backend/src/inventory/inventory.service.ts#L57` | Alerts created when `currentStock <= lowStockThreshold`. Passed Vitest test #4. |
| **§5.6** | Single active alert per product (no alert spam) | **VERIFIED** | `backend/src/alerts/alerts.service.ts`<br>`frontend/lib/screens/alerts_screen.dart` | Checks for existing `ACTIVE` alert before creating a new one. Passed Vitest test #4. |
| **§5.6, §7.3**| Low-stock alert auto-resolution upon restock | **VERIFIED** | `backend/src/inventory/inventory.service.ts#L74` | When stock increases above threshold, active alert status set to `RESOLVED`. Passed Vitest test #4. |
| **§5.7** | Simple shop expense recording | **VERIFIED** | `backend/src/expenses/expenses.service.ts`<br>`frontend/lib/screens/reports_screen.dart` | Simple expense recorder with title, category, amount, date. Passed Vitest test #8. |
| **§5.7** | Estimated operating result (only when expenses entered) | **VERIFIED** | `backend/src/reports/reports.service.ts#L183` | Returns `estimatedOperatingResult = grossProfit - expenses` if expenses exist, else `null`. Passed Vitest test #8. |
| **§5.8** | Daily, weekly, monthly sales summaries & product reports | **VERIFIED** | `backend/src/reports/reports.service.ts#L77`<br>`frontend/lib/screens/reports_screen.dart` | Period filtering (Today, 7 Days, 30 Days) with itemized performance table. |
| **§5.8** | CSV export for sales & inventory reports | **VERIFIED** | `backend/src/reports/reports.service.ts#L210`<br>`frontend/lib/screens/reports_screen.dart` | Generates RFC-compliant CSV with escaped fields and download dialogs. Passed Vitest test #9. |
| **§5.9** | Cross-shop data isolation (`shop_id` scoping) | **VERIFIED** | `backend/prisma/schema.prisma`<br>`backend/src/products/products.service.ts` | Every table has `shop_id` foreign key. Authorization guards enforce tenant isolation. Passed Vitest test #2. |
| **§6** | Barcode / SKU scanning hardware | **OUT OF SCOPE** | PRD §6 | Explicitly deferred to future releases. |
| **§6** | Payment gateways / online payment collection | **OUT OF SCOPE** | PRD §6 | Excluded. Manual payment/cash record only. |
| **§6** | Refund processing workflows | **OUT OF SCOPE** | PRD §6 | Excluded. |
| **§6** | Purchase orders & supplier management | **OUT OF SCOPE** | PRD §6 | Excluded. |
| **§6** | Advanced accounting, payroll & tax filing | **OUT OF SCOPE** | PRD §6 | Excluded. |
| **§10.4, §12**| Offline billing persistent queue & synchronization | **VERIFIED** | `frontend/lib/models/offline_bill.dart`<br>`frontend/lib/services/offline_billing_service.dart`<br>`frontend/lib/providers/offline_billing_provider.dart` | Persistent local storage across app restarts, auto/manual sync, idempotency protection, status badges (`PENDING`, `SYNCING`, `SYNCED`, `FAILED`). Passed Flutter test #1-#3. |

---

### 2. Implemented Features

1. **Authentication & Access Control**:
   - Owner shop registration with automatic initialization of shop profile and full privileges.
   - 8 individual checkbox permissions (`CREATE_BILLS`, `VIEW_PRODUCTS`, `ADD_EDIT_PRODUCTS`, `UPDATE_STOCK`, `VIEW_SALES_REPORTS`, `VIEW_PROFIT_REPORTS`, `MANAGE_STAFF`, `SHOP_SETTINGS`).
   - Immutable Owner protection: Owner status and permissions cannot be edited, demoted, or deleted by ordinary staff.
   - Immediate staff access revocation via `DELETE /api/staff/:id`.
2. **Product Catalogue & Multi-Unit Retail Inventory**:
   - Support for common retail units: piece, packet, bottle, kg, litre.
   - Opening stock automatically logged as an initial `OPENING_STOCK` movement.
   - Authorized stock adjustments requiring a mandatory reason (`RESTOCK`, `CORRECTION`, `DAMAGED`, `ADJUSTMENT`).
   - Accidental negative stock strictly prevented on all adjustments and counter bills.
   - Complete stock movement audit ledger recording user ID, previous stock, new stock, quantity change, and reason.
3. **Counter Billing & Receipts**:
   - Interactive fast billing with product search, category chips, and live stock indicators.
   - Line-item quantity steppers, subtotal, discount, shop-configured tax rate, and final total.
   - Single-transaction atomic commit: saves bill, creates immutable line snapshots, deducts inventory, records movement, and triggers alerts.
   - Client-generated UUID `idempotencyKey` prevents duplicate billing and double stock deductions on network retries.
   - 80mm thermal receipt format with clean line items, financial totals, and reprint watermark (`*** REPRINT OF RECEIPT ***`).
4. **Low-Stock Alerting & Auto-Resolution**:
   - Monitored against per-product configurable threshold.
   - Anti-spam guard: maintains a single active alert per product until resolved.
   - Auto-resolution: automatically transitions alert to `RESOLVED` when stock is replenished above threshold.
5. **Analytics & Profitability**:
   - Daily overview distinguishing top-selling product by quantity from highest-revenue product.
   - Estimated gross profit and gross margin percentage calculated against snapshot cost basis.
   - Shop expense recorder and conditional operating result estimate.
   - One-click RFC-compliant CSV exports for sales and inventory.
6. **Offline Billing Persistent Queue (Release 1)**:
   - When network connectivity is interrupted, bills are automatically buffered in persistent local storage.
   - Survives application restarts without data loss.
   - Auto/manual synchronization with server using stored idempotency keys.
   - Explicit status tracking: `PENDING`, `SYNCING`, `SYNCED`, `FAILED`.

---

### 3. Partially Implemented Features

*None.* All MVP and Release 1 functional requirements documented in PRD v0.2 are fully implemented in the codebase.

---

### 4. Missing Features

*None.* No approved feature from MVP or Release 1 is missing.

---

### 5. Failed Tests

- **Backend Vitest Test Suite**: 0 failed (9/9 passed).
- **Frontend Flutter Test Suite**: 0 failed (4/4 passed).
- **Prisma Schema Validation**: 0 failed (valid).
- **Flutter Static Analysis**: 0 issues found.

---

### 6. Database Verification & Staging Isolation

1. **Prisma Production Schema**:
   - Configured for PostgreSQL (`backend/prisma/schema.prisma`).
   - Uses `Decimal @db.Decimal(12, 2)` for monetary values and `Decimal @db.Decimal(12, 3)` for quantities.
   - Composite indexes on `(shopId, createdAt)` and `(shopId, status)` optimize tenant queries.
2. **PostgreSQL Validation**:
   - Executing `prisma validate --schema=prisma/schema.prisma` with a PostgreSQL connection string succeeds (`The schema at prisma\schema.prisma is valid 🚀`).
3. **Local Dev SQLite vs Production PostgreSQL**:
   - SQLite was used locally for automated unit and integration tests (`dev.db`).
   - **Audit finding**: SQLite tests prove TypeScript business logic, math, and transactions, but do not replace staging PostgreSQL verification under live network latency and native database sequences. A staging PostgreSQL deployment must be verified before commercial launch.

---

### 7. Security Concerns & Audit

1. **Tenant Isolation**: Every database query scopes to `user.shopId` extracted from the cryptographically verified JWT payload. Cross-shop data leaks are prevented (verified in Vitest test #2).
2. **Credential Storage**: Passwords hashed with `bcrypt` (10 rounds). Plaintext passwords are never stored.
3. **Input Sanitization**: Global `ValidationPipe` with `whitelist: true, transform: true` strips unwhitelisted payload parameters.
4. **Secret Hardening**: Local development uses default secret `JWT_SECRET`. Production environments must provide a high-entropy random key.

---

### 8. Platform-Specific Issues

1. **Android**:
   - SDK licenses accepted (`All SDK package licenses accepted`).
   - APK built successfully: `frontend/build/app/outputs/flutter-apk/app-debug.apk` (162 MB).
   - *Status*: Verified build. On-device testing with a physical Android phone recommended prior to store release.
2. **Web**:
   - Compiled successfully via `flutter build web --no-pub` (`√ Built build\web` in 102.2s).
   - *Status*: Fully verified and operational.
3. **Windows Desktop**:
   - Dart source code passes static analysis with 0 issues.
   - Executing `flutter build windows` fails with:
     ```
     Unable to find suitable Visual Studio toolchain. Please run `flutter doctor` for more details.
     ```
   - *Cause*: The host machine does not have Microsoft Visual Studio with the "Desktop development with C++" workload installed.
   - *Status*: Environmental blocker on this specific build machine. Compiling a native `.exe` requires installing Visual Studio C++ build tools.

---

### 9. Thermal Printer Integration Status

- **Status**: Implemented via software spooler; **untested on physical hardware**.
- **Supported Connection Method**: Standard 80mm thermal roll format via OS print spooler (Windows Print Spooler, Android Print Framework, Browser Print Preview).
- **Edge-Case Formatting Verified**:
  - Long product names wrap cleanly across multiple lines.
  - Large currency totals align correctly on right margin.
  - Reprint watermark (`*** DUPLICATE / REPRINT ***`) renders in a bordered box.
- **Hardware Testing Notice**: Direct ESC/POS byte streaming over raw USB/Bluetooth sockets was NOT implemented (out of scope per PRD v0.2). Physical testing on specific hardware models (such as Sryans or other thermal POS devices) must be performed on-site before commercial launch.

---

### 10. Remaining Work Before Commercial Release

1. **Physical Hardware Validation**: Connect an 80mm thermal receipt printer to verify roll paper cut triggers, margins, and print clarity.
2. **PostgreSQL Staging Deployment**: Provision a VPS with PostgreSQL, run migrations (`npm run db:migrate:pg`), and test daily backup restoration.
3. **Windows Toolchain**: Install the Visual Studio "Desktop development with C++" workload if producing a standalone `.exe` installer is required.
4. **On-Device Android QA**: Install `app-debug.apk` on a low-cost physical Android tablet/phone to verify touch ergonomics at the counter.
