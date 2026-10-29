# Seat, pickup and dropoff redesign

This change follows the Discovery UI in PR #9. The PR initially targets
`feature/mobile-discovery-ui`; retarget to `develop` after that parent merges.
The CI pull-request filter includes both branches so the same format, analyzer,
test and Android build checks run while the parent PR is open.

## Behavior

- The first three booking steps use the approved compact header, visual stepper,
  seat vectors, floor switcher, stop cards and bottom action dock.
- Seat selection, hold creation/release, navigation and the wall-clock countdown
  continue through BookingFlowBloc. Holds include optional authentication so a
  signed-in customer's hold retains customer ownership; guest holds remain valid.
- The seat mapper retains API IDs, prices, statuses and position labels. Explicit
  row/column coordinates are preserved when present. Current position-only API
  responses use the Web booking conventions: three columns per sleeper floor,
  or two seats on each side of the aisle for seated vehicles. Left/right labels
  take priority over sequential assignment. A B prefix alone does not create an
  upper floor for a seated vehicle.
- Passenger information, quote/voucher confirmation and payment retain their
  existing screens. The vehicle-detail sheet keeps its existing select button.

## Limits

The current API does not supply a complete physical layout for every vehicle.
These conventions do not establish that every limousine is physically 2+2 or
that every cabin uses three columns. Vehicle-specific geometry such as 2+1
requires an agreed layout contract/data; it is outside this change.

## Validation on 24 October 2026

- Flutter 3.38.7 / Dart 3.10.7; 357 Flutter tests passed; analyzer found no issues.
- Regression tests cover authenticated/guest request headers, API position
  mapping, explicit/mixed coordinates, inventory preservation, seat callbacks,
  narrow 320dp text 2x layouts and 640x360 landscape layouts.
- Real Mode debug APK built and was manually installed on realme 11. Source APK,
  phone Download copy and installed package SHA-256 matched:
  `c5b128923d9703dd9bb6398ddae84443d1a4e79ef2001dc310207bab27d941fe`.
- With the shared local Backend/DB: selected A02 on trip 765, retained an
  authenticated hold, selected pickup, advanced to dropoff, switched sleeper
  floors, then exited. DB readback confirmed hold release and seat return to
  `TRONG`. No booking, ticket or payment was created during this test.
- Trip 768 showed all 16 seated places in a 2+2 layout and no floor switcher.
  Read-only HTTP/model checks also preserved every seat on trips 766/767/768
  (22/34/16 seats). `tool/verify_live_seat_layout.dart` is a local read-only
  diagnostic for those existing QA trip IDs, not part of the app flow.

Full checkout/payment, bank settlement and chat were not retested in this pass.
Local logs, screenshots, private configuration and SQL backups stay outside Git.
The installed APK was built from the working source before the commit; a later
countdown whitespace change and diagnostic-only lint fix do not alter app logic.
CI artifacts have separate provenance and are not device-E2E evidence.

## Review F01 follow-up - 2026-10-27

Inventory refresh after hold expiry or a failed hold now uses resolveSeatLayout on the priced server seats, matching initialization. This brings the existing PR #11 behavior into this parent PR so PR #10 can be reviewed/merged independently. IDs, prices and status remain sourced from the same inventory response.

Added test/inventory_refresh_regression_test.dart from the independent review probe. It failed on the old HEAD and passes after this fix: unchanged API inventory keeps identical normalized positions after the simulated hold deadline. Full suite 358/358 passed. The test uses production BLoC/parser/repositories with MockClient, not a live backend/device check. No Backend/DB changes, review resolution or merge.
