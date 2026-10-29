# Mobile Step 6 — Payment UI

Branch: feature/mobile-payment-ui. Base: feature/mobile-trip-summary-ui / PR #12 at410ba93890766c600fd65e2823037b16f914c14a. Flutter3.38.7/Dart3.10.7.

## Behavior and scope

BookingPaymentView gives Step6 the same compact VexGo header/stepper, scrollable body and safe bottom dock as Steps1–5. Real Mode exposes VietQR only. Before order creation, the dock submits ConfirmPaymentEvent; after creation it checks the existing order. There is one primary CTA rather than duplicate body/dock buttons. The existing BLoC, repositories, backend contract, mutation/recovery behavior and success navigation are unchanged.

Step6Payment displays the amount, references and transfer details of the verified order, with copy actions and QR image error feedback. It distinguishes a temporary seat hold before creation from checkoutBooking.expiresAt after creation. A render-only timer/resume observer re-evaluates the absolute deadline; it does not poll payment APIs or restart the hold. Expired orders hide transfer instructions/QR while retaining existing-order reconciliation.

## Payment presentation guards

payment_display_state.dart centralizes the gates shared by body and dock:

- hasCurrentPaymentOrder requires pendingBookingId matching checkoutBooking.bookingId and no unknown booking outcome.
- hasConfirmedPayment requires that current order plus paymentConfirmed set by the production BLoC. Individual booking/payment status fields cannot override a rejected verification.
- canDisplayBankTransfer requires the matching current order, no confirmed payment, paymentPending UI state, VietQR selection, pending booking/payment statuses, positive matching order/payment amount, nonempty orderCode and an unexpired authoritative deadline.

A confirmed payment with a ticket-sync failure shows paid recovery, not an expired-payment warning. Cancelled/failed/unverified states do not invite a transfer; recheck uses the existing order and never blindly creates a replacement. Copy/QR/render actions do not authorize payment or issue tickets. Unknown outcomes and backend-blocked states preserve existing guards.

No changes to Backend/DB, Step1–5 layouts, financial calculation, promotion logic, boarding QR format, ticket-success authorization, SePay webhook setup or production bank settings are included. The passenger-card alignment change and BookingSuccess UI are separate work.

## Validation executed

- Full Flutter suite:435/435passed; payment_ui_test.dart contains17tests, including four additional regressions for rejected conflicting payment evidence, cancelled-before-deadline recheck with zero new bookings, order-identity confirmation fences and transfer eligibility at the deadline.
- Independent review probes:7/7passed, covering original paid-expiry/expired-instruction cases, inconsistent statuses, cancelled-order instructions and production-font responsive layouts.
- flutter analyze --no-pub:No issues found,17.9s.
- dart format --output=none --set-exit-if-changed lib test tool:176files,0changes.
- Tracked diff check passed; staged check is required before publication.

The source hashes recorded for the fixed APK match the final reviewed Step6/body/dock/helper/test source. Publication additionally updates this document and the CI base-branch trigger; those changes do not change the compiled payment behavior. Tests use fake/mocked repositories and in-memory credential storage, not live payment settlement.

Evidence remains outside Git at workspace/mobile-qa-evidence/payment-ui-independent-review:fix-full.log,fix-analyze.log,fix-probes.log,fix-apk-build.log andfix-apk-manifest.json. Earlier review reports are historical, with subsequent fix-verification notes; the original probe failures are not erased.

## APK and runtime limits

Fixed artifact:workspace/mobile-qa-evidence/ci-followup/app-debug-payment-ui-fixed.apk.

- Bytes:185694785.
- SHA256:810482D87906EF3424A879A53308225CE6D3E0007487463109F7C958AEBE48E8.
- Build:debug Real Mode, API http://127.0.0.1:4000/api/v1, public SePay Test Mode recipient MB/0000000001/PHAM MINH TAI through build defines.
- Kernel readback confirms the shared payment gates and intended API URL. Webhook secrets/API credentials are never included.

This APK was built from the reviewed working source before commit; CI will build its own artifact with commit provenance. It has not been installed/retested on a physical device. The earlier user SePay simulation hit an offline ngrok callback; no successful live booking→webhook→paid tickets run is claimed for this version. Restoring a public callback and checking a still-payable sandbox order are separate runtime tasks, not part of this PR's source change.

## Review and integration

PR base remains feature/mobile-trip-summary-ui while PR #12 is open. The CI workflow adds that base to its existing trigger; format/analyze/tests/build checks and exact-SHA provenance remain intact. Merge order and later retargeting must respect the parent PR chain. No self-approval, review-thread resolution or merge is performed.
