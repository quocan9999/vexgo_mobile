# Trip Summary & Promotions UI (Step 5)

This change implements and unifies **Step 5: Trip Summary & Promotions (Xác nhận đặt vé & mã ưu đãi)** (`BookingStep.tripSummary`) on the dedicated worktree `vexgo_trip_summary_ui_worktree` and branch `feature/mobile-trip-summary-ui`, on top of HEAD `0f161424ae5ae3f853d7301ffac0c9f92764ef3e` (PR #11 committed).

---

## 1. Architectural Overview & UI Unification

- **Visual Continuity across Steps 1 to 5**:
  - `BookingTripSummaryView` (`lib/features/user/booking/presentation/widgets/booking_trip_summary_view.dart`) provides a unified, production-grade Step 5 shell mirroring `BookingSelectionView` (Steps 1–3) and `BookingPassengerInfoView` (Step 4).
  - Embeds `BookingCompactHeader` with the signature primary red surface (`#DC2626`) containing:
    - Row 1: Back button, operator name, departure time, route arrow (`fromCityName → toCityName`), and `Chi tiết xe` modal action.
    - Row 2: `BookingStepperCompact` positioned at active step 5 (`currentStepIndex = 4`, "Xác nhận"), with prior steps 0–3 (`Chọn chỗ`, `Điểm đón`, `Điểm trả`, `Thông tin`) displaying checkmarks `✓` and navigable backward via `GoToStepEvent`.
  - Integrates `SeatHoldCountdownBar` directly below the compact header to maintain awareness of temporary seat reservation expiry.
  - Houses scrollable content in a `NestedScrollView` to smoothly coordinate header and body scrolling without clipping.
  - Implements `BookingTripSummaryDock` as a fixed bottom dock displaying:
    - Calculated / authoritative final amount (`CurrencyFormatter.format(state.finalAmount)`).
    - Promotional discount savings text (`Đã giảm ...`).
    - Prominent CTA button **"Thanh toán"** advancing to Step 6 (`BookingStep.payment`) via `NextStepEvent()`.

---

## 2. Comprehensive 5-Card Trip Summary Details

`Step5TripSummary` (`lib/features/user/booking/presentation/steps/step_5_trip_summary.dart`) was overhauled using `DiscoveryTheme` tokens (`VexGoJakarta`, `DiscoveryColors`, `DiscoveryTextStyles`, and elevation shadows):

1. **Trip & Route Card**:
   - Operator name, vehicle type, and departure date formatted in Vietnamese.
   - Timeline display of pickup point and dropoff point with exact full addresses (no ellipsis truncation cutting off street/district/city names).
   - Edit button (`Sửa đón/trả`) triggering `GoToStepEvent(1)` to adjust pickup/dropoff points.
2. **Selected Seats Card**:
   - Airline seat icon with total seat counter badge (`X chỗ`).
   - Wrap chip collection showing individual seat codes and prices (`A01 • 190.000 đ`).
   - Edit button (`Đổi ghế`) triggering `GoToStepEvent(0)` to modify seat selections while respecting the 5-seat maximum limit.
3. **Passenger Info Card**:
   - Passenger icon, full legal name, phone number, and email (with fallback indicators if empty).
   - Edit button (`Sửa`) triggering `GoToStepEvent(3)` to return to Step 4.
4. **Voucher & Promotions Card**:
   - Real quote-backed promotion system.
   - When a voucher/promo code is active: displays applied voucher card with green highlight, savings amount, and inline **"Bỏ mã"** action button (`RemoveVoucherEvent()`).
   - When no code is active: provides interactive selector button opening a clean promotional dialog (`Mã khuyến mãi` / `Kiểm tra mã`) calling `ApplyPromotionCodeEvent`.
   - Real-time quote state indicators: Linear loading bar during quote requests and retry button (`Cập nhật giá vé`) with clear error messaging on failure.
5. **Price Breakdown Card**:
   - Quoted seat subtotal (`Giá vé (X chỗ)`).
   - Service fee display (`Phí dịch vụ: Miễn phí` or quoted fee).
   - Promotional discount deduction in secondary brand color (`-30.000 đ`).
   - Final total amount (`Tổng tiền cần thanh toán`).
6. **Guarantee & Policy Banner**:
   - Security shield icon (`Icons.verified_user_rounded`) with assurance copy confirming ticket validity upon payment verification.

---

## 3. Accessibility & Responsive Engineering

- Responsive design rigorously supports both extreme and compact viewports:
  - **Narrow Viewport (320×740) with 2.0× Text Scaling**:
    - Each summary card header incorporates a `LayoutBuilder` that automatically transitions the header into a vertical column when constraints are constrained (`maxWidth < 280` and `textScale > 1.3`), preventing any horizontal `RenderFlex` overflow.
    - Price breakdown rows dynamically stack label and price vertically when text scale exceeds standard limits.
  - **Landscape Viewport (640×360) with 2.0× Text Scaling and View Insets**:
    - Bottom dock wrapped in `ConstrainedBox` with internal `SingleChildScrollView` to prevent vertical overflow while keeping CTA actions reachable.
    - `NestedScrollView` allows unhindered vertical scrolling across all summary cards.

---

## 4. Quality Gates & Test Suite Verification

### Code Formatting & Static Analysis
- `dart format --output=none --set-exit-if-changed lib test tool`:
  - **170 files checked, 0 changed** (Exit code `0`).
- `flutter analyze --no-pub`:
  - **No issues found!** (Exit code `0`).
- `git diff --check`:
  - **0 whitespace / merge conflict issues** (Exit code `0`).

### Automated Test Suite
- Full test suite execution:
  - Command: `& 'D:\quantrong\LTDD\flutter\bin\flutter.bat' test --no-pub`
  - Result: **408 / 408 tests passed** (Exit code `0`).
- Dedicated Step 5 test suite:
  - File: `test/trip_summary_ui_test.dart`
  - **9 / 9 tests passed**:
    1. Step 5 embeds `BookingCompactHeader` on red surface with active step 5 (Xác nhận) and completed checkmarks on steps 1–4.
    2. Displays all 5 core summary sections with functional Edit buttons navigating back to prior steps.
    3. Quote loading, error, and retry states show appropriate indicators and control CTA state.
    4. Promotion dialog workflow: enter valid code, apply, show discount, and remove code cleanly.
    5. Bottom dock displays accurate total, discount savings, and tapping CTA advances to Step 6.
    6. Seat hold expiry disables CTA and reveals warning message.
    7. Responsive check: 320×740 narrow screen with 2.0× text scale renders without overflow and keeps all actions reachable.
    8. Responsive check: Landscape 640×360 with 2.0× text scale and keyboard insets scrolls cleanly without overflow.
    9. Full flow integration: Step 4 -> Step 5 -> Step 6 with `BookingTripSummaryView`.

---

## 5. Real Mode Debug APK Build Manifest

The debug Real Mode APK was compiled against the live backend API configuration:
- Build command:
  ```powershell
  & 'D:\quantrong\LTDD\flutter\bin\flutter.bat' build apk --debug --no-pub `
    --dart-define=DEMO_MODE=false `
    --dart-define=API_BASE_URL=http://127.0.0.1:4000/api/v1 `
    --dart-define=SEPAY_BANK_ID=MB `
    --dart-define=SEPAY_ACCOUNT_NUMBER=0000000001 `
    '--dart-define=SEPAY_ACCOUNT_NAME=PHAM MINH TAI'
  ```
- **Output Artifact**: `mobile-qa-evidence/ci-followup/app-debug-trip-summary-ui.apk`
- **File Size**: `159,305,657` bytes (~151.9 MB)
- **SHA-256**: `3CF43F565D45F24BAD92EBD72B619AF4A0347F48069CBA1F9F6639AFC83B0A6A`
- **Compiled Kernel Verification**:
  - `HasApiBase`: `True` (`http://127.0.0.1:4000/api/v1`)
  - `HasTripSummaryView`: `True` (`BookingTripSummaryView`)
  - `HasStep5`: `True` (`Step5TripSummary`)
  - `HasSepayAccount`: `True` (`PHAM MINH TAI`)

---

## 6. Commit & Repository Policy Compliance

- All modifications reside on the dedicated worktree `vexgo_trip_summary_ui_worktree` on branch `feature/mobile-trip-summary-ui`.
- **NO commits, pushes, or merges** were executed, per project instructions.
- Step 6 and backend/database layers were preserved unchanged.

## Follow-up fixes - 2026-10-26

Implemented after independent review (not committed/pushed):
- R1: authoritative quote acceptance and matching promotion code now control success display. Requested, loading and rejected codes no longer show a success check or valid-code claim. The attempted code remains available for editing/rechecking.
- R2: Edit buttons have a minimum 48dp touch target.
- Added three regressions for rejected codes, accepted-to-pending/invalidated quote transitions, and edit target size. Existing accepted-code/removal and payment navigation tests remain green.
- Seat-map fixes inherited from the PR #11 worktree are also present locally: shared cross-floor cell width and flexible front-label height; two new regressions cover these.
- Final execution: 413/413 tests passed; analyzer No issues found (15.9s); format 171 files, 0 changes; tracked diff check passed.
- No new APK/device/live-payment validation in this follow-up. Prior APK manifest above describes the Agent build before these fixes.
- Evidence: workspace/mobile-qa-evidence/trip-summary-independent-review/fix-all-tests.log and fix-analyze.log.

## Follow-up fixes - 2026-10-27 (Passenger Card Alignment)

Implemented approved Đề xuất 3 for Step 5 Passenger Info Card:
- Shortened labels to exact strings: `Họ tên`, `Số điện thoại`, `Email` (removed colon `:` and redundant phrases).
- In `_buildRowInfo`: aligned icons to first line (`top: 1.5`), fixed label column to consistent width (`labelWidth = 90`), and expanded value column with right alignment (`TextAlign.end`).
- Geometry verified: all 3 labels share the same left axis, all 3 values share the same right axis, and typical email addresses (`nguyen221205@gmail.com`) fit cleanly on a single line on 390dp without dropping `.com`.
- Responsive verified: wraps cleanly on 320dp 2.0x and 640x360 landscape without overflow.
- Test suite: 420/420 tests passed; `dart format` (172 files, 0 changes) and `flutter analyze` clean.
- Debug APK: `mobile-qa-evidence/ci-followup/app-debug-trip-summary-aligned.apk`
  - File Size: `185,644,233` bytes (~177.04 MB)
  - SHA-256: `26B26E5D1CA2CD3C01A22E2AA2FC95A4967969A4EDFCD0C2EB1004376711836C`
  - Kernel verified: `HasApiBase`, `HasTripSummaryView`, `HasStep5`, `HasSepayAccount`, `HasSepayBank` all `True`.
