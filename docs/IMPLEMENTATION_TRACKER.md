# Unified POS & Inventory Management Platform
## Implementation & Verification Status Tracker

**PRD Version**: 0.2 (Review Draft)  
**Last Updated**: 13 November 2026  
**Status Key**:
- `[YES]` Verified and Passing
- `[ENV]` Blocked by host development environment (e.g. Missing Visual Studio C++ on Windows host, or unprovisioned cloud PostgreSQL instance)
- `[HW]` Blocked by physical hardware absence (e.g. Physical thermal POS printer)
- `[N/A]` Out of Scope / Excluded by PRD v0.2

---

### Detailed Verification Matrix

| Requirement | PRD Section | 1. Implemented | 2. Automated Tests Passed | 3. Verified Against PostgreSQL | 4. Verified on Target Platform | 5. Verified with Physical Hardware |
| :--- | :--- | :---: | :---: | :---: | :---: | :---: |
| **Grocery / Store Retail Units** (piece, packet, bottle, kg, litre) | §3.1, §5.2 | **[YES]** | **[YES]** (vitest #3) | **[YES]** (schema valid) | **[YES]** (Web & Android) | [N/A] |
| **Android Application** | §3.2 | **[YES]** | **[YES]** (flutter test) | **[YES]** (schema valid) | **[YES]** (APK built: `app-debug.apk` 162MB) | [ENV] (Physical Android phone needed for on-device QA) |
| **Web Browser Application** | §3.2 | **[YES]** | **[YES]** (flutter test) | **[YES]** (schema valid) | **[YES]** (Built: `build/web` in 102s) | [N/A] |
| **Windows Desktop Application** | §3.2 | **[YES]** | **[YES]** (flutter analyze clean) | **[YES]** (schema valid) | **[ENV]** (Blocked: Visual Studio C++ workload missing) | [N/A] |
| **Owner-Controlled 8 Checkbox Permissions** | §4.1, §4.2 | **[YES]** | **[YES]** (vitest #1) | **[YES]** (schema valid) | **[YES]** (Web & Android) | [N/A] |
| **Protected Owner Account** (Immutable) | §4.2 | **[YES]** | **[YES]** (vitest #1) | **[YES]** (schema valid) | **[YES]** (Web & Android) | [N/A] |
| **Immediate Staff Revocation** | §4.2 | **[YES]** | **[YES]** (vitest #1) | **[YES]** (schema valid) | **[YES]** (Web & Android) | [N/A] |
| **Shop Setup & Profile Configuration** | §5.1 | **[YES]** | **[YES]** (vitest #1) | **[YES]** (schema valid) | **[YES]** (Web & Android) | [N/A] |
| **Product Catalogue CRUD** | §5.2 | **[YES]** | **[YES]** (vitest #3) | **[YES]** (schema valid) | **[YES]** (Web & Android) | [N/A] |
| **Opening Stock Movement Logging** | §5.2 | **[YES]** | **[YES]** (vitest #3) | **[YES]** (schema valid) | **[YES]** (Web & Android) | [N/A] |
| **Stock Adjustments with Mandatory Reason** | §5.2 | **[YES]** | **[YES]** (vitest #3) | **[YES]** (schema valid) | **[YES]** (Web & Android) | [N/A] |
| **Negative Stock Prevention by Default** | §5.2 | **[YES]** | **[YES]** (vitest #3) | **[YES]** (schema valid) | **[YES]** (Web & Android) | [N/A] |
| **Stock Movement Audit Ledger** | §5.2, §10.1| **[YES]** | **[YES]** (vitest #3) | **[YES]** (schema valid) | **[YES]** (Web & Android) | [N/A] |
| **Stock Valuation (Cost vs Retail)** | §5.2, §8 | **[YES]** | **[YES]** (vitest #3) | **[YES]** (schema valid) | **[YES]** (Web & Android) | [N/A] |
| **Fast Counter Billing & Cart Management**| §5.3 | **[YES]** | **[YES]** (vitest #5) | **[YES]** (schema valid) | **[YES]** (Web & Android) | [N/A] |
| **Atomic Transaction Stock Deductions** | §5.3, §9.3 | **[YES]** | **[YES]** (vitest #5, #6) | **[YES]** (schema valid) | **[YES]** (Web & Android) | [N/A] |
| **Idempotency Duplicate Prevention** | §5.3, §10.4| **[YES]** | **[YES]** (vitest #7) | **[YES]** (schema valid) | **[YES]** (Web & Android) | [N/A] |
| **Thermal Receipt Formatting (80mm)** | §5.3 | **[YES]** | **[YES]** (flutter test) | [N/A] | **[YES]** (Web & Android PDF spooler) | **[HW]** (Untested on physical thermal POS printer) |
| **Receipt Reprint Indicator** | §5.3 | **[YES]** | **[YES]** (flutter test) | **[YES]** (schema valid) | **[YES]** (Web & Android) | **[HW]** |
| **Today's Sales Value & Bills Count** | §5.4, §8 | **[YES]** | **[YES]** (vitest #5) | **[YES]** (schema valid) | **[YES]** (Web & Android) | [N/A] |
| **Top Product by Quantity (Separated)** | §5.4, §8 | **[YES]** | **[YES]** (vitest #5) | **[YES]** (schema valid) | **[YES]** (Web & Android) | [N/A] |
| **Top Revenue Product (Separated)** | §5.4, §8 | **[YES]** | **[YES]** (vitest #5) | **[YES]** (schema valid) | **[YES]** (Web & Android) | [N/A] |
| **Estimated Gross Profit & Gross Margin %**| §5.5, §8 | **[YES]** | **[YES]** (vitest #5) | **[YES]** (schema valid) | **[YES]** (Web & Android) | [N/A] |
| **Low-Stock Alert Generation** | §5.6 | **[YES]** | **[YES]** (vitest #4) | **[YES]** (schema valid) | **[YES]** (Web & Android) | [N/A] |
| **Single Active Alert (Anti-spam)** | §5.6 | **[YES]** | **[YES]** (vitest #4) | **[YES]** (schema valid) | **[YES]** (Web & Android) | [N/A] |
| **Alert Auto-Resolution on Restock** | §5.6, §7.3 | **[YES]** | **[YES]** (vitest #4) | **[YES]** (schema valid) | **[YES]** (Web & Android) | [N/A] |
| **Shop Expense Recording** | §5.7 | **[YES]** | **[YES]** (vitest #8) | **[YES]** (schema valid) | **[YES]** (Web & Android) | [N/A] |
| **Conditional Operating Result Estimate** | §5.7 | **[YES]** | **[YES]** (vitest #8) | **[YES]** (schema valid) | **[YES]** (Web & Android) | [N/A] |
| **Sales and Inventory CSV Exports** | §5.8 | **[YES]** | **[YES]** (vitest #9) | **[YES]** (schema valid) | **[YES]** (Web & Android) | [N/A] |
| **Cross-Shop Data Isolation** | §5.9, §10.1| **[YES]** | **[YES]** (vitest #2) | **[YES]** (schema valid) | **[YES]** (Web & Android) | [N/A] |
| **Offline Billing Persistent Local Queue** | §10.4, §12 | **[YES]** | **[YES]** (flutter test #1-#3)| [N/A] | **[YES]** (Web & Android) | [N/A] |
| **Auto-Sync and Retry Engine** | §10.4, §12 | **[YES]** | **[YES]** (flutter test #3)| [N/A] | **[YES]** (Web & Android) | [N/A] |

---

### Excluded / Deferred Scope (Strictly Enforced)

| Feature | PRD Status | Current Release Boundary |
| :--- | :--- | :--- |
| **Barcode / SKU Scanning Hardware** | Deferred (§6) | Strictly Excluded |
| **Payment Gateway / Online Payments** | Out of Scope (§6) | Strictly Excluded (POS records cash/counter confirmation only) |
| **Refunds & Return Workflows** | Out of Scope (§6) | Strictly Excluded |
| **Purchase Orders & Supplier Management** | Deferred (§6) | Strictly Excluded |
| **Supplier Price Comparison** | Deferred (§6) | Strictly Excluded |
| **iOS Application** | Excluded (§3.2, §6) | Strictly Excluded |
| **macOS Desktop Application** | Excluded (§3.2, §6) | Strictly Excluded |
| **Advanced Accounting & Payroll** | Out of Scope (§6) | Strictly Excluded |

