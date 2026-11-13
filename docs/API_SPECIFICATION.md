# REST API Specification
## Unified POS & Inventory Management Platform

All protected endpoints require the HTTP Header:
```http
Authorization: Bearer <jwt_access_token>
```

---

### 1. Authentication & Shop Setup (`/api/auth`)

#### `POST /api/auth/register-shop`
Registers a new shop profile and owner account with full permissions.
- **Request Body**:
  ```json
  {
    "shopName": "City Provisions",
    "ownerFullName": "Ramesh Sharma",
    "username": "owner",
    "password": "password123",
    "currency": "₹",
    "address": "128 Market Road",
    "phone": "+91 98765 43210"
  }
  ```
- **Response** (`201 Created`):
  ```json
  {
    "accessToken": "eyJhbGciOi...",
    "user": { "id": "...", "username": "owner", "fullName": "Ramesh Sharma", "isOwner": true, "permissions": ["..."] },
    "shop": { "id": "...", "name": "City Provisions", "currency": "₹", "taxPercentage": 0 }
  }
  ```

#### `POST /api/auth/login`
Authenticates an owner or staff member.
- **Request Body**:
  ```json
  { "username": "cashier", "password": "password123" }
  ```
- **Response** (`200 OK`): Returns JWT access token, user profile, shop details, and permitted checkbox actions.

#### `GET /api/auth/me`
Validates session and returns current user and shop details.

---

### 2. Shop Configuration (`/api/shop`)

#### `GET /api/shop/profile`
Returns active shop profile.

#### `PUT /api/shop/profile`
Updates shop settings.
- **Permission Required**: `SHOP_SETTINGS` (or Owner)
- **Request Body**:
  ```json
  {
    "name": "City Supermarket",
    "currency": "₹",
    "taxPercentage": 5.0,
    "receiptHeader": "Welcome to City Supermarket",
    "receiptFooter": "Thank you for shopping with us!"
  }
  ```

---

### 3. Staff Accounts & Permissions (`/api/staff`)

#### `GET /api/staff`
Lists all staff members for the current shop.
- **Permission Required**: `MANAGE_STAFF` (or Owner)

#### `POST /api/staff`
Creates a new staff member with individual checkbox permissions.
- **Permission Required**: `MANAGE_STAFF` (or Owner)
- **Request Body**:
  ```json
  {
    "fullName": "Priya Patel",
    "username": "cashier",
    "password": "password123",
    "permissions": ["CREATE_BILLS", "VIEW_PRODUCTS"]
  }
  ```

#### `PUT /api/staff/:id`
Updates staff member's permissions or active status.
- **Permission Required**: `MANAGE_STAFF` (or Owner)
- **Note**: Owner account is immutable and cannot be demoted or disabled.

#### `DELETE /api/staff/:id`
Immediately revokes a staff member's access (`isActive = false`).
- **Permission Required**: `MANAGE_STAFF` (or Owner)

---

### 4. Products & Catalogue (`/api/products`)

#### `GET /api/products`
Lists products with current stock and pricing.
- **Permission Required**: `VIEW_PRODUCTS`
- **Query Parameters**: `search`, `category`, `includeInactive`

#### `POST /api/products`
Creates a product and records opening stock in movement history.
- **Permission Required**: `ADD_EDIT_PRODUCTS`
- **Request Body**:
  ```json
  {
    "name": "Basmati Rice 1kg",
    "category": "Grains",
    "unit": "kg",
    "purchaseCost": 85.00,
    "sellingPrice": 120.00,
    "openingStock": 50,
    "lowStockThreshold": 10
  }
  ```

#### `PUT /api/products/:id`
Updates product details or pricing.
- **Permission Required**: `ADD_EDIT_PRODUCTS`

#### `DELETE /api/products/:id`
Deactivates product (`isActive = false`).
- **Permission Required**: `ADD_EDIT_PRODUCTS`

---

### 5. Inventory & Stock Adjustments (`/api/inventory`)

#### `POST /api/inventory/adjust`
Records an authorized stock adjustment with a mandatory reason.
- **Permission Required**: `UPDATE_STOCK`
- **Request Body**:
  ```json
  {
    "productId": "uuid-here",
    "quantityChange": 20,
    "movementType": "RESTOCK",
    "reason": "Supplier shipment received"
  }
  ```
- **Note**: Prevents negative stock. Automatically triggers or resolves low-stock alerts.

#### `GET /api/inventory/movements`
Returns full stock movement audit ledger.
- **Permission Required**: `VIEW_PRODUCTS`

#### `GET /api/inventory/summary`
Returns total product count, units on hand, cost valuation, retail valuation, and low stock count.
- **Permission Required**: `VIEW_PRODUCTS`

---

### 6. Billing & Receipts (`/api/billing`)

#### `POST /api/billing`
Commits a bill atomically, creates line snapshots, deducts stock, and logs stock movements.
- **Permission Required**: `CREATE_BILLS`
- **Request Body**:
  ```json
  {
    "idempotencyKey": "c1f7a0b3-9092-4871-9ce4-cb3211562b70",
    "discountAmount": 10.00,
    "notes": "Cash counter sale",
    "items": [
      { "productId": "uuid-1", "quantity": 2, "unitPrice": 120.00 },
      { "productId": "uuid-2", "quantity": 1, "unitPrice": 34.00 }
    ]
  }
  ```
- **Response**: Full formatted bill and receipt payload. Duplicate requests with same `idempotencyKey` return original bill safely.

#### `GET /api/billing`
Lists completed bills with date filtering and pagination.
- **Permission Required**: `VIEW_SALES_REPORTS`

#### `GET /api/billing/:id`
Returns bill details.
- **Permission Required**: `CREATE_BILLS`

#### `POST /api/billing/:id/reprint`
Increments reprint count and returns bill formatted with `isReprint: true`.
- **Permission Required**: `CREATE_BILLS`

#### `POST /api/billing/:id/void`
Voids a bill and reverses stock deductions with audit log.
- **Permission Required**: `SHOP_SETTINGS` (Owner)

---

### 7. Low-Stock Alerts (`/api/alerts`)

#### `GET /api/alerts`
Lists active low-stock alerts.
- **Permission Required**: `VIEW_PRODUCTS`

#### `POST /api/alerts/:id/acknowledge`
Acknowledges an alert.
- **Permission Required**: `UPDATE_STOCK`

---

### 8. Expenses (`/api/expenses`)

#### `POST /api/expenses`
Records a shop expense.
- **Permission Required**: `SHOP_SETTINGS`
- **Request Body**:
  ```json
  {
    "title": "Shop Electricity",
    "category": "UTILITY",
    "amount": 1200.00,
    "notes": "Refrigeration and lights"
  }
  ```

#### `GET /api/expenses`
Lists expenses within date range.
- **Permission Required**: `VIEW_PROFIT_REPORTS`

---

### 9. Reports & CSV Exports (`/api/reports`)

#### `GET /api/reports/today-overview`
Returns today's sales value, bill count, top product by units, and top revenue product.
- **Permission Required**: `VIEW_SALES_REPORTS`

#### `GET /api/reports/sales-profit-summary`
Returns revenue, cost basis, estimated gross profit, gross margin %, and product rankings.
- **Permission Required**: `VIEW_SALES_REPORTS`

#### `GET /api/reports/export/sales-csv`
Downloads sales and profit summary as CSV.
- **Permission Required**: `VIEW_SALES_REPORTS`

#### `GET /api/reports/export/inventory-csv`
Downloads stock on hand and valuation as CSV.
- **Permission Required**: `VIEW_PRODUCTS`

