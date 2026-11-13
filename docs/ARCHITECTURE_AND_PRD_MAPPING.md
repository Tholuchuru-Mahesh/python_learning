# Architecture & PRD Compliance Mapping Matrix
## Unified POS & Inventory Management Platform (PRD v0.2 Review Draft)

This document maps all features and requirements defined in the approved PRD (MVP and Release 1) to their respective backend services, database schemas, frontend components, and automated test validations.

---

### 1. Executive Summary & Core Platform Scoping

| PRD Section | Requirement Description | Technical Implementation | Status |
| :--- | :--- | :--- | :--- |
| **§3.1** | Grocery, general store, mini-supermarket workflows | Common retail units (`piece`, `packet`, `bottle`, `kg`, `litre`), fast counter billing, instant receipt generation | **COMPLETED** |
| **§3.2** | Multi-Platform client (Android, Web, Windows Desktop) | Flutter single codebase with responsive NavigationRail / NavigationBar and desktop/web dialogs | **COMPLETED** |
| **§3.2, §6** | Exclude iOS, macOS, Barcode hardware, Gateways, Refunds, POs | Strictly omitted from MVP & Release 1 | **COMPLIANT** |
| **§9.2** | NestJS Modular Monolith API | 9 isolated modules (`auth`, `shop`, `staff`, `products`, `inventory`, `billing`, `alerts`, `expenses`, `reports`) | **COMPLETED** |
| **§9.2** | PostgreSQL Relational Database with Prisma ORM | Full Prisma schema with tenant-scoped isolation (`shop_id`), decimal precision, and migrations | **COMPLETED** |

---

### 2. Module-by-Module Technical Specification

#### 2.1 Shop Setup & Authentication (PRD §5.1)
- **Relevant PRD Section**: §5.1 Shop setup and account
- **Backend Implementation**:
  - `backend/src/auth/`: `AuthService`, `AuthController`, `RegisterShopDto`, `LoginDto`
  - `backend/src/shop/`: `ShopService`, `ShopController`, `UpdateShopDto`
  - `backend/src/common/guards/`: `JwtAuthGuard`
- **Database Tables**:
  - `shops`: `id`, `name`, `address`, `phone`, `currency`, `tax_percentage`, `receipt_header`, `receipt_footer`, timestamps.
  - `users`: `id`, `shop_id`, `full_name`, `username`, `password_hash`, `is_owner`, `is_active`, `permissions`, timestamps.
- **Frontend Implementation**:
  - `frontend/lib/screens/login_screen.dart`: Shop registration, Owner/Staff login, demo account shortcuts.
  - `frontend/lib/screens/settings_screen.dart`: Shop profile, currency, tax %, thermal receipt headers.
  - `frontend/lib/providers/auth_provider.dart`: JWT token storage via `SharedPreferences`.
- **Validation**: Test case 1 in `test/prd_compliance.spec.ts`.

#### 2.2 Owner-Controlled Staff Permissions (PRD §4.1 & §4.2)
- **Relevant PRD Section**: §4.1 & §4.2 User Accounts and Permission Model
- **Core Principle**: No fixed hardcoded roles (e.g. Cashier or Manager as primary access model). Access is granted via 8 granular checkboxes:
  1. `CREATE_BILLS`: Create and save customer bills
  2. `VIEW_PRODUCTS`: View product catalogue and item details
  3. `ADD_EDIT_PRODUCTS`: Create products or update product details
  4. `UPDATE_STOCK`: Authorized stock adjustments with mandatory reasons
  5. `VIEW_SALES_REPORTS`: Sales totals and item-wise sales reports
  6. `VIEW_PROFIT_REPORTS`: Cost basis, sales value, estimated gross profit
  7. `MANAGE_STAFF`: Create staff accounts and assign permissions (Owner-only by default)
  8. `SHOP_SETTINGS`: Shop profile, tax/receipt settings, alert thresholds (Owner-only by default)
- **Backend Implementation**:
  - `backend/src/common/constants/permissions.constant.ts`
  - `backend/src/common/guards/permissions.guard.ts` (Backend-enforced check; Owner has universal access)
  - `backend/src/staff/`: `StaffService`, `StaffController`
- **Frontend Implementation**:
  - `frontend/lib/screens/staff_screen.dart`: Checkbox permission assignment dialog, active status toggle, immediate revocation action.
  - `frontend/lib/screens/main_layout.dart`: Dynamic menu hiding based on active staff member's permissions.
- **Validation**: Tested in vitest suite; verified Owner account cannot be revoked or altered by ordinary staff.

#### 2.3 Product Catalogue & Inventory Management (PRD §5.2)
- **Relevant PRD Section**: §5.2 Product catalogue and inventory
- **Backend Implementation**:
  - `backend/src/products/`: `ProductsService`, `ProductsController`
  - `backend/src/inventory/`: `InventoryService`, `InventoryController`
- **Database Tables**:
  - `products`: `id`, `shop_id`, `name`, `description`, `category`, `unit`, `purchase_cost`, `selling_price`, `current_stock`, `low_stock_threshold`, `is_active`.
  - `stock_movements`: `id`, `shop_id`, `product_id`, `user_id`, `bill_id`, `movement_type`, `quantity_change`, `previous_stock`, `new_stock`, `reason`, `created_at`.
- **Frontend Implementation**:
  - `frontend/lib/screens/products_screen.dart`: Catalogue search, category filter, Add/Edit product dialog.
  - `frontend/lib/screens/inventory_screen.dart`: Inventory valuation KPIs, stock adjustment dialog with mandatory reason, live stock preview, negative stock prevention warning.
- **PRD Compliance**:
  - Opening stock recorded automatically as an initial `OPENING_STOCK` movement.
  - Negative stock is strictly prevented on adjustments and bill commits (PRD §5.2).
  - Stock movement ledger captures user, reason, before/after quantities for 100% auditability.
- **Validation**: Test case 2 in `test/prd_compliance.spec.ts`.

#### 2.4 Fast POS Counter Billing & Receipts (PRD §5.3, §9.3, §10.1, §10.4)
- **Relevant PRD Section**: §5.3 Billing and receipt printing, §9.3 Architecture, §10.4 Idempotency
- **Backend Implementation**:
  - `backend/src/billing/`: `BillingService`, `BillingController`
  - Atomic database transaction (`$transaction`):
    - Check client-generated `idempotencyKey`. If bill already exists, return it without duplicate charges or stock deduction.
    - Check available stock >= requested quantity.
    - Calculate line totals, subtotal, discount, tax, final total, cost basis, estimated gross profit.
    - Generate sequential bill number: `BILL-YYYYMMDD-XXXX`.
    - Create `BillItem` immutable snapshots (`unitPriceSnapshot`, `unitCostSnapshot`, `quantity`, `lineTotal`, `lineProfit`).
    - Deduct stock exactly once.
    - Log `StockMovement` of type `SALE`.
    - Check `lowStockThreshold` and upsert single active `LowStockAlert` if stock <= threshold.
- **Frontend Implementation**:
  - `frontend/lib/screens/billing_screen.dart`: Fast product search, category chips, interactive cart with steppers, discount input, tax preview, complete bill button.
  - `frontend/lib/widgets/receipt_dialog.dart`: Thermal receipt 80mm layout preview with browser/system print dialog support, itemized breakdown, tax, and reprint indication (`*** REPRINT OF RECEIPT ***`).
  - Bill history tab allows reprinting any historical bill with incremented reprint count.
- **Validation**: Test cases 3 & 4 in `test/prd_compliance.spec.ts`.

#### 2.5 Low-Stock Alerts (PRD §5.6 & §7.3)
- **Relevant PRD Section**: §5.6 Low-stock alerts
- **Backend Implementation**:
  - `backend/src/alerts/`: `AlertsService`, `AlertsController`
  - Automatically triggered during billing and inventory adjustments when `newStock <= lowStockThreshold`.
  - Maintains **one active alert per product** to prevent spam (PRD §5.6).
  - Resolves active alert automatically when stock is replenished above threshold (PRD §7.3).
- **Frontend Implementation**:
  - Top navigation bar notification badge showing active alert count.
  - `frontend/lib/screens/alerts_screen.dart`: List of active alerts with product details, stock vs threshold, and "Acknowledge" button.
- **Validation**: Test case 5 in `test/prd_compliance.spec.ts`.

#### 2.6 Sales Analytics, Gross Profit & Expenses (PRD §5.4, §5.5, §5.7, §5.8, §8)
- **Relevant PRD Section**: §5.4 Sales overview, §5.5 Profit and cost comparison, §5.7 Expenses, §5.8 Reports, §8 Analytics definitions
- **Backend Implementation**:
  - `backend/src/reports/`: `ReportsService`, `ReportsController`
  - `backend/src/expenses/`: `ExpensesService`, `ExpensesController`
- **Core Formulas**:
  - `Estimated Gross Profit` = `Sales Revenue - Discounts - Recorded Cost Basis of Sold Units` (PRD §5.5 & §8)
  - `Gross Margin %` = `(Estimated Gross Profit / Sales Revenue) * 100` (PRD §8)
  - `Top Selling Product by Units` = Product with highest units sold today (PRD §5.4)
  - `Top Revenue Product` = Product with highest sales revenue today (strictly separated from quantity ranking, PRD §5.4)
  - `Estimated Operating Result` = `Estimated Gross Profit - Recorded Expenses` (only displayed when expense data is recorded, PRD §5.7)
- **CSV Exports**:
  - `GET /api/reports/export/sales-csv`: Formatted CSV with product performance and summary KPIs.
  - `GET /api/reports/export/inventory-csv`: Formatted CSV with stock on hand, valuation at cost/retail, and alert flags.
- **Frontend Implementation**:
  - `frontend/lib/screens/reports_screen.dart`: KPI cards for today, period selector (Today, 7 Days, 30 Days), Gross Profit breakdown, Expense recorder modal, Product performance table, and one-click CSV download dialogs.
- **Validation**: Test case 6 in `test/prd_compliance.spec.ts`.

