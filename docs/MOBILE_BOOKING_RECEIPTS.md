# Mobile booking/payment receipts

## Scope and entry points

This is read-only booking/payment evidence, following Customer Web's invoice
page. It is not VAT invoice issuance and does not generate a new boarding QR.
PDF export, sharing and tax-provider integration are outside this change.

Open the receipt lookup from the My Tickets app-bar action. A receipt button is
also available after booking success, in ticket detail and after guest ticket
lookup. Buttons prefill the current ticket's code and contact using transient
navigation data; neither value is serialized into the route URL.

## Existing API contract

Source checked against `quocan9999/vexgo` backend commit
`f79d753952b7add7886b9497636879da3b45f24b`, including Web's
`apps/web/src/features/payments/components/invoice-page.tsx` and the booking /
ticket services. No backend or database migration is required by this feature.

1. `POST /api/v1/tickets/lookup` with `ticketCode` and `phoneNumber` resolves
   the entered ticket / booking / order code to a fresh ticket and booking link.
2. `GET /api/v1/bookings/:bookingId/detail` reads the complete booking. Guest
   capabilities travel in `x-booking-code` and `x-booking-phone` headers. For an
   account booking the shared API client supplies the current authenticated
   session; a 403 never falls back to anonymous access.
3. The result must match the resolved booking ID, booking code and ticket
   membership. The entered code must belong to this response.

The backend owns authorization: account bookings require their owning account;
guest bookings require the valid booking capability and matching phone.
Knowing an account booking's code and phone alone does not grant access.

## Display and state rules

- Both booking state (`DA_THANH_TOAN` or `HOAN_TAT`) and payment state
  (`DA_THANH_TOAN`) must confirm payment. Pending, cancelled, expired and
  unknown states cannot produce a paid receipt.
- Required identifiers, timestamps, tickets and monetary fields must be valid.
  Missing amounts are never converted to zero. An explicitly paid zero-total
  booking remains valid. Decimal strings and JSON numbers are accepted.
- Show all tickets, seats, passenger, company, route, departure, pickup/dropoff,
  discount, cargo items/fee and authoritative booking total. Missing optional
  display fields are shown as unavailable rather than invented.
- Loading and failed refresh remove the previous receipt. Editing the form
  clears its previous result and retry credentials. Newer requests win over
  late responses. Resuming the app refreshes a loaded receipt.
- Session changes clear the receipt and form, invalidate pending requests and
  block stale navigation data / route-held ticket entry buttons. The user must
  reopen lookup under the new session.
- Copy explicitly distinguishes the receipt from a VAT invoice and boarding QR.

## Verification performed on 2026-10-22

Local Flutter 3.38.7 / Dart 3.10.7:

- `dart format --output=none --set-exit-if-changed lib test`: 161 files,
  no changes.
- `flutter analyze --no-pub`: no issues.
- `flutter test --no-pub`: 356 passed, including 30 new receipt tests.
- Debug Android APK build in Real Mode succeeded. API URL for the local device
  build was `http://127.0.0.1:4000/api/v1` through ADB reverse to the isolated
  API on host port 4014.

The 30 new tests cover parsing, incomplete/unknown payment evidence, monetary
validation, code/booking/ticket consistency, current-session JWT/header behavior,
403 handling, request races, refresh failure, logout, stale route data and small
screen rendering. HTTP in these committed unit/widget tests is mocked.

Separately, four actual HTTP repository probes passed against the real local
Nest API and dedicated `vexgo_trip_contract_test` MySQL database: owner receipt
with JWT, denial of anonymous access to the owner's receipt, wrong-phone 404,
and valid guest capability access. These probes use real transport, not the
Flutter test framework's default HTTP override.

Physical Android verification used a manually installed APK whose pulled
installed file matched SHA256
`6C56D1588DF38A78025E632D9FECA1E64C023132369609E2F199781EF35A743F`.
On-device checks confirmed booking-code and ticket-code lookup, two tickets of
150,000 VND each with total 300,000 VND, refresh, and wrong-phone rejection with
the old receipt removed. Screenshots and raw logs are retained outside Git in
the workspace's `mobile-qa-evidence/ci-followup/receipt-*` artifacts.

Device and guest HTTP checks used explicitly synthetic paid-state read fixtures
in the approved isolated test DB. They verify receipt access and rendering,
not bank settlement, production data or VAT issuance. No shared DB was reset or
seeded and no real transfer was performed. Account-session/logout edge cases
were covered by automated tests; account-owner transport was exercised by the
real HTTP probe rather than logging in on the Android device.

The feature branch starts from Mobile `develop` at
`7981d22aa932794cd8d4e63f2f1ba37fbc590864`; it does not include the separate,
unmerged support-chat feature branch. CI results should be checked against the
receipt PR's current head before merge.
