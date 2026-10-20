# Local database upgrade decision — develop 8b33925

## Approved and completed

User explicitly approved backup and migration. A 763005-byte SQL backup was created before applying all six migrations with `prisma migrate deploy` (exit 0), without reset, seed, migration SQL changes or deletion of chat history. Backup SHA256: `4C190D0F34932845001F2E25955E94D717CFC8A7EFA48C53A9211F5B61C4A981`; path `../mobile-qa-evidence/backups/vexgo-before-develop-8b33925.sql` (kept outside this repository). QA rechecked migrate status on 19 October 2026: 30 migrations, database up to date, exit 0. Existing promotions require reconfiguration following the approved legacy migration.

The following is the original pre-decision review, preserved as the basis for approval.

Read-only `npm exec prisma -- migrate status` found six pending migrations and one database-only chat migration. No migration, reset or seed has been executed.

Pending migrations:

1. `20261009010000_add_shipment_management_permissions`: insert new permissions/default grants.
2. `20261009020000_add_shipment_operator_permissions`: add operator grants.
3. `20261014170000_allow_guest_bookings_without_customer_account`: allow nullable `DonGiaoDich.khachHangId` for guests.
4. `20261014181000_add_sepay_transaction_id`: add unique nullable SePay transaction reference.
5. `20261015184828_add_promotion_quota_usage_ledger`: add quota/usage tables, booking discount and constraints. **Rewrites existing promotions as LEGACY_UNCONFIGURED**, assigns quota 1 and fills missing code/end-date. Existing promotions require reconfiguration before use.
6. `20261016110000_add_promotion_management_permissions`: add promotion permissions/default grants.

Database additionally records `20261013150000_add_chat_support_conversations_and_messages`, absent from develop. Preserve that history and its tables; do not reset or mark migrations applied to conceal drift.

If authorized: take a local database backup first, then use the project's existing `prisma migrate deploy` path to apply the six pending migrations without reset, seed or deletion of chat history. If the tool refuses history/schema drift, stop and report the exact blocker. Do not alter existing migration SQL.

Until a decision is made, mobile HTTP-fixture regression tests and APK validation can proceed, but live Backend E2E against develop cannot be claimed.
