# VexGo Mobile execution plan — 2026-10-18

> Updated after the user's instruction to fetch the latest development branch: Mobile `team/develop@ba66748` was already an ancestor of the working branch. Backend was switched to `develop` and fast-forwarded to `origin/develop@8b339250a95b6825cef591b1d10ae537ba1068f4`. The initial Backend findings below describe the original snapshot only. The current contract supports guest booking and real SePay/VietQR settlement; wallet-provider production creation remains unavailable. See `MOBILE_FINAL_REPORT.md` for the current matrix.

## Audited baseline and scope (initial snapshot)

- Mobile: `quocan9999/vexgo_mobile`, PR #5, `feature/seat-hold-and-countdown`, HEAD `4aea4235505d69df61f1602e820fb915bbcab82e`. Remote head verified equal to local. Integration branch: `fix/mobile-contract-integrity`.
- Existing user changes preserved: `lib/app/routes.dart`, `lib/data/adapters/city_search_adapter.dart`, `lib/features/user/home/presentation/widgets/search_form_card.dart`, `test/lead_review_findings_regression_test.dart`. They are excluded from agent ownership and implementation commits.
- Backend contract: local `vexgo_web`, `feature/realtime-chat-support`, HEAD `0fec20ba1aae8ff0518c9dcebdd6cbe4b017c130`, remote head verified equal. API defaults to local port 4000; no configuration pins a Git branch, so deployment parity remains NEEDS_VERIFICATION. Backend remains read-only; its untracked seed script is untouched.
- PR #5 read live: 62 review threads, 6 unresolved. Existing resolved findings are rechecked against code; no thread will be resolved by this work.
- Preserve BLoC → Repository → DataSource architecture and dependency versions. No merge, deployment, backend API changes, or external comments.
- Runtime has three concurrent child slots. Five requested roles run in phases. Writers use separate Git worktrees; reviewers and QA are read-only against integrated code.

## Feature matrix before implementation

| Feature | Mobile status | Backend status | Finding | Priority | Dependency | Owner |
|---|---|---|---|---|---|---|
| Login/register/OTP | PARTIAL | COMPLETE | Auth summary used as profile; fetch authoritative /me | P1 | Auth + /me DTO | flutter-feature-engineer |
| Refresh/session/logout | PARTIAL | COMPLETE | No automatic refresh/replay; protect rotation and logout races | P1 | /auth/refresh | orchestrator |
| View/edit profile | PARTIAL | COMPLETE | Session lost visually on profile error; fabricated registration points message | P1 | Authoritative /me | flutter-feature-engineer |
| Trip search/detail | NEEDS_VERIFICATION | COMPLETE | Preserve current city/search user fixes, verify suite and live read contract | P1 | Trips/routes | api-architect + QA |
| Real seats/hold/release | PARTIAL | COMPLETE | Countdown decrements local ticks; lifecycle/consumed-hold race | P1 | Absolute expiresAt | booking-payment-engineer |
| Guest Checkout | BLOCKED_BY_BACKEND | BLOCKED_BY_BACKEND | Booking/payment creation requires authenticated principal | P1 | Backend guest ownership/security contract | Lead/backend |
| Booking/payment recovery | PARTIAL | PARTIAL | IDs lost after partial failure; avoid duplicate create; unknown POST outcome lacks idempotency recovery | P0 | Booking/payment APIs | booking-payment-engineer |
| Real provider payment | BLOCKED_BY_BACKEND | BLOCKED_BY_BACKEND | Backend rejects non-demo creation; demo gateway URLs do not provide real payment | P0 | Backend provider implementation | Lead/backend |
| Payment confirmation + real ticket | PARTIAL | COMPLETE | Fabricated TicketModel on API failure and immediate SUCCESS; fetch full /tickets/:id | P0 | Status + booking summary + full ticket | booking-payment-engineer |
| My Tickets/detail/review | PARTIAL | COMPLETE | Session cache stale; review booking lookup throws outside catch | P1 | Auth lifecycle + booking lookup | flutter-feature-engineer |
| Notifications/read state | PARTIAL | COMPLETE | Login/logout sync absent; mark-read failure unhandled | P1 | Auth lifecycle | flutter-feature-engineer |
| UI/loading/error/retry | PARTIAL | PARTIAL | Protected tabs need guest/error states; checkout must show honest recovery/blockers | P2 | Feature fixes above | feature/booking engineers |
| Regression/device E2E | NEEDS_VERIFICATION | NEEDS_VERIFICATION | SDK installed; adb currently has no device | P1 | Integrated changes + runtime | qa-e2e-engineer |

COMPLETE means the source contract exists here; it does not imply live production verification.

## Initial task ledger and acceptance criteria

This table records the plan before implementation. Final task states, subsequent Backend re-audit and executed evidence are maintained in [MOBILE_FINAL_REPORT.md](MOBILE_FINAL_REPORT.md), sections 5–10. Do not interpret the initial TODO/IN_PROGRESS values as the current delivery status.

| Task | Goal / scope | Owner | Dependency | Acceptance criteria | Priority | Status | Test evidence |
|---|---|---|---|---|---|---|---|
| API-01 | Audit real controllers/DTO/envelopes and PR #5 | api-architect | Baseline | Matrix and API gaps linked to current source | P1 | IN_PROGRESS | Live PR read; local/remote SHAs verified |
| BP-01 | Authoritative ticket and staged payment recovery; booking repository + booking feature | booking-payment-engineer | API-01 contract | No synthetic real ticket; PENDING→SUCCESS fetches full ticket; retries preserve IDs; no duplicate creates | P0 | TODO | Add backend-shaped HTTP/repository/BLoC regressions |
| BP-02 | Absolute hold expiry and lifecycle; booking feature | booking-payment-engineer | Seat-hold DTO | Clock jump/resume expires hold; consumed hold never resets payment; concurrent actions guarded | P1 | TODO | Clock + release + concurrency regressions |
| FE-01 | Auth profile and protected-data synchronization; app.dart, auth/profile, tickets, notification features | flutter-feature-engineer | API-01 contract | GET /me after auth; guest never loads protected APIs; login reloads; logout/account switch clears stale data including in-flight responses | P0 | TODO | Auth/lifecycle/widget tests |
| FE-02 | Error/retry/session UI and guarded review/read operations | flutter-feature-engineer | FE-01 | API errors emitted and retryable; existing session survives profile failure | P1 | TODO | Negative network/auth tests |
| NET-01 | Refresh/replay and secure session race handling; api_client.dart/token_storage.dart | orchestrator | Auth refresh contract | Single-flight rotation; one replay; invalid refresh clears credentials; no automatic retries on network mutations; logout cannot resurrect tokens | P1 | TODO | HTTP refresh, concurrent 401, invalid/timeout/logout regressions |
| SEARCH-01 | Guard out-of-order search results and remove unverified date prices/cancellation claims | orchestrator | Audited trip search source | Earlier requests cannot replace later route/date results; prices shown only for loaded date; policy follows backend quote | P1 | IN_PROGRESS | Completer race regression and widget checks |
| QA-01 | Independent quality gates and regression validation | qa-e2e-engineer | Integrated fixes | Record actual format/analyze/test/APK exits; device E2E if available, otherwise explicit blocker | P1 | TODO | Pending execution |
| SEC-01 | Independent security/correctness review | security-code-reviewer | Integrated fixes | Evidence/repro steps for remaining P0/P1; up to 3 repair rounds per finding | P0 | TODO | Pending review |
| DOC-01 | Before/after matrix, task states, files/commits, gates and readiness | orchestrator | QA-01 + SEC-01 | Honest final report; no readiness claim with backend blockers or missing mandatory gates | P1 | TODO | Final report |

## Execution order

### Completion round after a266508 (scope agreed before editing)

| Task | Goal / scope | Owner | Dependency | Acceptance criteria | Priority | Status | Test evidence |
|---|---|---|---|---|---|---|---|
| FE-03 | Paginated trip search, authoritative trip/ticket detail and public guest lookup; search_trips/my_bookings + trip datasource | flutter-feature-engineer | Backend develop 8b33925; isolated vexgo_completion_worktree | Fresh details, retry, no stale session responses, guest code/phone lookup without login | P1 | DONE in component scope | 25 feature regressions; independent review 31 PASS |
| BP-03 | Server quote/promotion validation, contact eligibility, zero-total checkout and visible recovery codes; booking feature/datasource/repository/models | booking-payment-engineer | Backend quote contract; isolated vexgo_pricing_worktree | Decimal parsing; stale quote rejected; no local discount used as authoritative total; zero-total skips provider; no duplicate creates | P0 | DONE in component scope | 15 pricing regressions; independent review 20 PASS |
| AUTH-03 | Change password through AuthBloc -> repository -> datasource, profile dialog; remove fabricated profile stats/unsupported setting success | orchestrator | Verified POST /auth/change-password and 8..72 UTF-8 byte DTO | Password whitespace preserved; old/new/confirmation validation; errors stay visible; duplicate submit blocked; logout invalidates late result; real API success only | P1 | DONE in component scope | 7 regressions; independent review 29 PASS |
| QA-02 / SEC-02 | Independent gates and review for completion changes | QA / security reviewer | Integrated completion commits | Four mandatory gates, independent negative/race probes, explicit device/provider limits | P0 | DONE for available checks | Round 2 format 150/0 changes, analyze, 283 tests, debug APK all PASS; independent 31 tests PASS. Device/provider live remain unverified |
| SEC-FE-QR / SEC-FE-REFUND | Repair snapshot QR modal across session changes and unconfirmed refund-complete claim; modal/card/detail + widget regressions | flutter-feature-engineer | Independent reviewer 3 failing probes on f50b230; isolated completion worktree | Open QR disappears/clears on account/token/reader invalidation; cancelled ticket never claims settled refund without proof; rerun independent probes | P1 | DONE (repair round 1 of max 3) | Same 3 external repro probes unchanged now PASS at 0a58e3f; original FAIL retained |

1. Complete audit and confirm task ownership/dependencies before source edits.
2. Run baseline tests. Implement BP and FE in separate worktrees; implement NET on integration branch without touching their files or existing user changes.
3. Integrate scoped commits, run regression suite, then independent QA and security review. Repair findings within three rounds, rerun affected regression checks.
4. Record final matrix, unresolved backend gaps, exact gates and READY / NOT READY FOR MERGE.

Mandatory gates: `dart format --output=none --set-exit-if-changed .`, `flutter analyze`, `flutter test`, `flutter build apk --debug`. Device/integration evidence must distinguish real Backend calls from HTTP fixtures and demo mode.
