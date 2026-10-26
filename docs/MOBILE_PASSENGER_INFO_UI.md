# Passenger information UI (Step 4)

This change completes **Step 4: Thông tin hành khách** (`BookingStep.passengerInfo`) on top of the approved PR #10 seat, pickup and dropoff UI (`feature/mobile-seat-pickup-ui-redesign`, commit `6d9d4064764312bd425051cf87b7edb987b52870`).

## Behavior

- **Visual continuity with PR #9 & PR #10**:
  - `BookingCompactHeader` (`lib/features/user/booking/presentation/widgets/booking_stepper.dart`) provides a shared compact red header (`#DC2626`) across Steps 1–4 (`BookingSelectionView` and `BookingPassengerInfoView`), containing Row 1 (Back button, `trip.operatorName`, `departureTime • date • fromCityName → toCityName`, and inline `Chi tiết xe`) and Row 2 (`BookingStepperCompact` inside the same red header surface).
  - `BookingStepperCompact` renders all 6 steps of `BookingStep` (`Chọn chỗ`, `Điểm đón`, `Điểm trả`, `Thông tin`, `Xác nhận`, `Thanh toán`), automatically scrolls the active step (`4 Thông tin` on Step 4) into the visible horizontal viewport on mount and step changes without resetting scroll offset on 1-second countdown ticks, allows tapping completed steps (`Chọn chỗ`, `Điểm đón`, `Điểm trả`) via `GoToStepEvent`, and blocks future steps (`Xác nhận`, `Thanh toán`) and busy/locked states.
  - `BookingPassengerInfoView` provides a scoped Step 4 shell using `DiscoveryTheme` (`VexGoJakarta` and `DiscoveryColors`), `BookingCompactHeader`, `SeatHoldCountdownBar`, and responsive bottom action dock (`Quay lại` outline + `Tiếp tục` `#FF5B24`).
  - Steps 1–3 continue using `BookingSelectionView`; Steps 5–6 (`Step5TripSummary`, `Step6Payment`) remain on their existing checkout screens.
- **Focused 3-field contact card**:
  - `Step4PassengerInfo` renders a single vertical contact card (`Thông tin liên hệ cho đơn đặt vé`) with three fields:
    1. `Họ và tên *` (required, trimmed length `>= 2`)
    2. `Số điện thoại *` (required, Vietnamese mobile regex `^(?:0|\+84)[35789][0-9]{8}$`)
    3. `Email (tùy chọn)` (optional; validated against `^[^\s@]+@[^\s@]+\.[^\s@]+$` only when non-empty)
  - A compact selection summary strip at the top of Step 4 displays the currently held seat codes and selected pickup/dropoff points.
  - Non-authoritative fields (`passengerNote` input and Demo Mode `savePassengerInfo` checkbox) are omitted from the UI so users are not misled into thinking notes or profile changes are persisted by `POST /api/v1/bookings`. The underlying `BookingFlowState` and `UpdatePassengerInfoEvent` fields remain intact for backward compatibility.
- **State, validation, and session integrity**:
  - Logged-in customer info (`hoTen`, `soDienThoai`, `email`) prefills into Step 4 via `InitBookingFlowEvent`. Editing Step 4 updates only the booking draft (`UpdatePassengerInfoEvent`) and invalidates any stale quote (`clearQuote: true`) without mutating `AuthBloc` / `AuthRepository`.
  - If `AuthBloc` logs out or switches accounts while `BookingFlowScreen` is mounted, the route is permanently fenced and shows a neutral session-change screen. The user must leave and reopen booking under the current account. The old form/QR is hidden even during initialization or locked checkout; queued edits and late init/quote responses cannot restore it.
  - The session fence clears draft contact/quote/promotion data and retires a hold not yet used to create a booking. A late hold response is also released. A failed release is never claimed as successful; the backend expiry remains authoritative. A dispatched booking with an unknown outcome is not released or replayed. Valid booking/payment IDs returned after the fence are retained in the route's recovery state, while subsequent payment and ticket requests stop. This is route-local recovery, not a new durable recovery store.
  - `TextEditingController` synchronization in `Step4PassengerInfo.didUpdateWidget` only updates when external state diverges from controller text, preserving cursor position and Vietnamese IME composing ranges while typing.
  - `BookingFlowBloc._onNextStep` verifies that an active, non-expired `seatHold` exists before advancing past Step 1; if the hold has expired while on Step 4, `NextStepEvent` triggers hold expiration handling (`_onTickCountdown`) and returns to `BookingStep.seatSelection` instead of advancing to Step 5.

## Original Agent validation on 24 October 2026 (superseded APK)

- Toolchain: `Flutter 3.38.7` / `Dart 3.10.7`.
- Quality gates:
  - `dart format --output=none --set-exit-if-changed .` passed (`0` changed).
  - `flutter analyze --no-pub` passed (`No issues found!`).
  - `flutter test --no-pub --reporter expanded` passed (`369` tests passed, including `12` new Step 4 widget and regression tests in `test/passenger_info_ui_test.dart`).
- Real Flutter render screenshots captured in `mobile-qa-evidence/passenger-info-implementation/`:
  - `step4-normal-390-844.png`
  - `step4-validation-error-390-844.png`
  - `step4-keyboard-390-844.png`
  - `step4-320-740-text2.png` & `step4-320-740-text2-scrolled.png`
  - `step4-640-360-text2.png` & `step4-640-360-text2-scrolled.png`
- Real Mode debug APK (`DEMO_MODE=false`, `API_BASE_URL=http://127.0.0.1:4002/api/v1`):
  - **Do not install this original artifact:** phone port 4002 did not match the standard USB forwarding. Use the fixed APK documented below.
  - Output copy: `mobile-qa-evidence/ci-followup/app-debug-passenger-info-ui.apk`
  - Size: `159,279,017` bytes
  - SHA-256: `d2c354414d2f024af994a63d244915246d57f560a6aff3b51babe26d5d1d63b9`
  - Physical Android device / local backend port `4002` were not attached/listening during this pass (`adb devices` returned empty; `4002` not listening), so live device ADB install was not claimed.

## Review fixes (24 October 2026)

- R1/R2: session invalidation is synchronous at the mounted route boundary and permanent for that route. Start a fresh route to prefill the current account. Initialization, hold creation, quote, booking/payment continuation and ticket hydration all respect the fence. Booking/payment responses already dispatched retain valid recovery IDs; unknown booking outcomes stay unknown and are never automatically replayed.
- Added 8 regression tests: delayed init after logout/account switch; late hold cleanup; late booking/payment ID retention without continuation; unknown POST outcome; session changes while booking/ticket hydration is awaiting a response. The existing Step 4 logout test now verifies the neutral screen and the release request. The delayed-init tests also exercise 640×360, text 2x and keyboard inset 220dp. The neutral screen scrolls so its exit action remains reachable.
- `flutter test --no-pub --reporter expanded`: **377/377 passed**, exit 0 (`fix-full-tests-final.log`).
- `flutter analyze --no-pub`: **No issues found**, exit 0 (`fix-analyze-final.log`).
- `dart format --output=none --set-exit-if-changed lib test tool`: **166 files, 0 changed**, exit 0 (`fix-format.log`).
- `git diff --check`: passed. No commit/push/merge performed for these fixes.
- Fixed Real Mode debug APK: `mobile-qa-evidence/ci-followup/app-debug-passenger-info-ui-fixed.apk`.
  - API: `http://127.0.0.1:4000/api/v1`; USB forwarding: phone `4000` → PC `4002`.
  - Public SePay **test** receiver only: MB / `0000000001` / `PHAM MINH TAI`. No webhook secret included. Do not transfer real money.
  - Size: `159,279,017` bytes; SHA-256: `d4f4e7deafa969c02435707526eb869288d2bc598462ec56438a29faeb8f8c9e`.
  - Inspected compiled kernel: new session fence and session-change copy present, port 4000 present, old API URL port 4002 absent.
  - Copied to Android `Download/Vexgo`, phone SHA-256 matched. API health `ok` and USB reverse verified. Manual APK update/device smoke verification still pending at this documentation checkpoint.
- Evidence and fixed build manifest: `mobile-qa-evidence/passenger-info-review/`. The first focused test run was interrupted because the new widget fixture awaited AuthBloc closure under fake async; fixture teardown was corrected and the focused rerun passed (39 tests), followed by the final complete suite above. No production failure was hidden.

### Physical device follow-up

User manually installed the fixed APK; installed `base.apk` SHA-256 matched the artifact above. On realme 11 with the real local API/main database, executed search → select A02 on trip 765 (25 October, 08:00) → hold → pickup/dropoff → Step 4 account prefill → Back/Continue with unchanged contact → Step 5 API quote `260.000đ`. Opened/dismissed keyboard and autofill without editing; contact remained unchanged. Exited the booking flow and verified inventory A02 `TRONG → DANG_GIU → TRONG` through the API. No booking/payment was created. No profile edit was performed.

This completes the device smoke for Steps 1–5 and hold release. Auth-switch/delayed-response races remain automated-fixture verification, not device reproduction; no full booking/payment E2E claim. Private local evidence: `mobile-qa-evidence/passenger-info-review/device-smoke.md` and UI snapshots/screenshots, which must stay outside Git/PR attachments. No commit/push/merge performed.

## Unified Booking Header + 6-Step Stepper follow-up (24 October 2026)

- Unified Step 4 header with Steps 1–3 via `BookingCompactHeader` and 6-step `BookingStepperCompact` inside the red `#DC2626` header block (`lib/features/user/booking/presentation/widgets/booking_stepper.dart`, `booking_selection_view.dart`, `booking_passenger_info_view.dart`, `booking_flow_screen.dart`).
- Added 4 widget and regression tests in `test/passenger_info_ui_test.dart` (Tests 13–16) covering Step 4 stepper visibility/auto-scroll, semantics & `>= 48dp` hit targets, backward step navigation preserving draft contact + `seatHold`, blocking future steps and busy/locked states, countdown tick scroll/focus stability, and `220dp` keyboard inset responsiveness.
- Updated Step 4 render screenshots in `mobile-qa-evidence/passenger-info-implementation/` (`step4-normal-390-844.png`, `step4-validation-error-390-844.png`, `step4-keyboard-390-844.png`, `step4-320-740-text2.png`, `step4-320-740-text2-scrolled.png`, `step4-640-360-text2.png`, `step4-640-360-text2-scrolled.png`).
- Quality gates:
  - `dart format --output=none --set-exit-if-changed lib test tool`: **166 files, 0 changed**, exit 0.
  - `flutter analyze --no-pub`: **No issues found!**, exit 0.
  - `flutter test --no-pub --reporter expanded`: **381/381 passed**, exit 0.
  - `git diff --check`: passed.
- Real Mode debug APK (`DEMO_MODE=false`, `API_BASE_URL=http://127.0.0.1:4000/api/v1`, public test SePay defines `MB` / `0000000001` / `PHAM MINH TAI`):
  - Output copy: `mobile-qa-evidence/ci-followup/app-debug-booking-header-stepper.apk` (preserves `app-debug-passenger-info-ui-fixed.apk` separately).
  - Size: `185,591,023` bytes.
  - SHA-256: `92c5eba99d6edd6ac2202a18d742852ecf9124a317cdffd33a765eed0ae42e2d`.
  - Compiled kernel verified: `http://127.0.0.1:4000/api/v1` and `BookingCompactHeader` present, old port `4002` URL absent.
  - Physical Android phone was not connected at build time (`adb devices -l` empty), so copy to `/sdcard/Download/Vexgo/` was not performed in this step. No commit/push/merge performed.

## Header responsive review fixes — H1/H2 (24 October 2026)

- Step 4 now keeps one stable `NestedScrollView`/form hierarchy across keyboard and viewport changes, preserving the same contact controllers/focus nodes and editing selection/composing. The header/countdown can scroll with the outer slivers as in Steps 1–3; the form is no longer recreated at the 260dp available-height breakpoint.
- The Stepper tracks width, effective label text size, direction and compact mode. Active-step reveal is scheduled after layout when geometry or current step changes. Reveal targets only the Stepper's horizontal position, leaving ancestor vertical scrolling alone. Countdown rebuilds with unchanged geometry do not reset the user's scroll offset.
- Added regression tests 17/18: mounted geometry changes, plus landscape keyboard open/close/open with controller identity, focus, selection and Vietnamese composing preservation. The two independent probes that failed before the fixes now pass unchanged.
- Actual verification: 26 focused tests passed; **383/383 full-suite tests passed**; analyzer 0 issues; format 166 files/0 changed; diff check passed. Logs: `mobile-qa-evidence/booking-header-rereview/fix-*.log`.
- Three additional render cases passed using a copied harness outside the repo; images saved separately in `mobile-qa-evidence/booking-header-rereview/fixed-renders/` so original Agent renders remain available. Render fixtures are not live-device evidence.
- No changes to API payload, Backend/DB, session fence, hold/transaction recovery or payment configuration. No commit/push/merge performed. User chose to inspect the new APK later; physical device verification of H1/H2 remains pending.
- Fixed debug APK: `mobile-qa-evidence/ci-followup/app-debug-booking-header-stepper-fixed.apk`, **185,590,796 bytes**, SHA-256 `8ff213bca76aff7fb3fc2f06416083c7dcd1482d6484fb66b0a0c2ed28d18517`. Build exit 0; inspected kernel confirms `_layoutGeometry` and phone API port 4000, with old API port 4002 absent. Real Mode and the same public SePay TEST defines were retained. Previous Agent APK kept separately. Exact build/gate metadata: `mobile-qa-evidence/booking-header-rereview/fixed-build-manifest.json`.
