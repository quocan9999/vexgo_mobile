# PR #5 — Lead review handoff, 19 October 2026

Ready for code review; **not ready for merging the complete application** until the live verification below is completed. Existing Lead review threads remain open for the Lead to assess.

## Exact reviewed/tested source

- Original PR head: `4aea4235505d69df61f1602e820fb915bbcab82e`.
- Integration source freeze: `0a58e3f59cd8214f3e4e3d18c5d70a0118c61f2b` plus the four original search/navigation changes recorded by QA.
- Those four changes are now committed separately as `a7fba6f9febc69b4fe87d7d1ad8307142e92acff`. Their patch was compared with QA's preserved original and matches. The working tree was clean at this commit.
- On that clean committed source, `flutter analyze --no-pub` passed with no issues and `flutter test --no-pub` passed all **283 tests**. Later handoff commits change documentation/evidence only.
- The previously built APK uses exactly the same Dart/native source contents. No source implementation changed after the four successful final gates; committing existing changes did not change their contents.

## Six open Lead threads: implementation and evidence to inspect

| Lead finding | Resulting behavior | Checked-in regression evidence |
|---|---|---|
| Auth response parsed as profile / fabricated user fields | Login/register require tokens and hydrate authoritative `/me`; invalid profile fails rather than fabricating identity | `test/auth_lifecycle_regression_test.dart`, `test/auth_and_profile_flow_test.dart` |
| Fake ticket after payment / full-ticket lookup failure | Paid booking/order and full authoritative tickets required; pending/error keeps recovery context and never fabricates a boarding pass | `test/booking_integrity_regression_test.dart`, `test/payment_integrity_test.dart` |
| Countdown subtracts local ticks | Absolute `expiresAt`, wall-clock/resume reconciliation, consumed-hold and release guards | `test/booking_integrity_regression_test.dart`, `test/seat_hold_flow_test.dart` |
| Tickets/notifications load before login and retain previous account | Session-bound load, synchronous clear, discard late responses, fresh detail/public guest lookup | `test/feature_errors_regression_test.dart`, `test/feature_completion_regression_test.dart`, `test/session_refresh_regression_test.dart` |
| Review booking lookup throws outside catch | Lookup and submission errors are caught and emitted without crashing the handler | `test/feature_errors_regression_test.dart` (review booking lookup failure), `test/phase3_reviews_and_notifications_test.dart` |
| Payment test only constructs an exception | HTTP/repository/BLoC scenarios exercise actual create/status/full-ticket mappings, pending/retry, amount/status mismatch and zero-total paths | `test/payment_integrity_test.dart`, `test/booking_integrity_regression_test.dart`, `test/pricing_completion_regression_test.dart`, `test/round_4_findings_test.dart` |

Independent review additionally found and verified repairs for open QR surviving session changes and cancelled tickets claiming a completed refund. The same three original external reproductions passed unchanged after repair. Checked-in feature regressions cover these behaviors. Review evidence groups reuse tests and must not be added together as a unique test count.

## Executed gates and APK

All four final gate commands exited **0**: format (150 files, 0 changes), analyze, **283 tests**, and debug APK build. Machine-readable gate timestamps/results: [review-evidence/pr5-quality-gates.json](review-evidence/pr5-quality-gates.json).

The first format attempt failed traversing generated build directories. The identical command passed after SDK `flutter clean` and locked dependency restore. Kotlin incremental compilation logged a C:/D: cache issue; compiler fallback completed the build successfully. No dependency upgrade, check bypass or assertion weakening was used.

APK: `app-debug-final.apk`, **157963377 bytes**, SHA256 **`189C493BB9F7ACE3BCB738002DAF11682294D53E09301658898B30D1B05F8E21`**. The binary and full raw logs remain local QA artifacts outside Git; they are not uploaded or linked as a GitHub-hosted download. The repository contains the reproducible source, gate summary and artifact checksum.

Build: `flutter build apk --debug --dart-define-from-file=<local-public-vietqr-config.json>`. Only public receiving-bank fields and `DEMO_MODE=false` belong in that local file; never include webhook secrets. On a physical device, configure `API_BASE_URL` or forward local port 4000 with ADB. The validated APK uses the local development API, not a production endpoint.

## Live evidence and merge prerequisites

- Actual local Backend GET search/detail/seats checks passed. Real hold lifecycle passed: create 201, conflicting hold 409, release 200, inventory restored; normal hold audit history remains.
- Backend aligned to `develop@8b339250a95b6825cef591b1d10ae537ba1068f4`. Authorized backup + six existing migrations completed without reset/seed; later migrate status passed with 30 migrations. Legacy promotions require reconfiguration.
- Both existing future trips return quote 404, so successful live pricing/promotion/booking is **not verified**. Missing applicable fare is a plausible configuration cause, not independently proven from the response alone. A Lead/backend owner needs to provide valid test fares/promotions.
- No Android device/AVD or live OTP/account/payment-provider/ticket issuance E2E was available. Never treat fixture settlement as a real bank transfer. API was inactive at final health check.
- Production wallet providers remain unavailable; Real UI exposes VietQR. Unknown booking POST outcome fails closed because no idempotency recovery API exists. Guest recovery context does not survive app restart.
- Review dependencies between session, booking, payment and ticket changes together. If approving a smaller merge, extract dependency-complete commits into a separate candidate and rerun gates for that candidate. This PR is not merged automatically.

Full before/after matrix, task ledger and findings: [MOBILE_FINAL_REPORT.md](MOBILE_FINAL_REPORT.md). File manifest: [MOBILE_CHANGED_FILES.md](MOBILE_CHANGED_FILES.md).
