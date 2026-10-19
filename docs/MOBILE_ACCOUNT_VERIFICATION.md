# Mobile account verification — 19–20 October 2026

Scope: Mobile only, branch `feature/mobile-account-live-verification`, based on
PR #5 candidate `77e2d50`. Backend contract is `vexgo/develop@8b33925`.
No Backend source, migration, environment or account-role changes were made.

## Live local/device evidence

Realme RMX3636 / Android15 with Real Mode Mobile and the local Backend:

- The owner entered passwords directly on the device. A new customer account was
  registered using the owner's supplied identity. No passwords, tokens, OTPs or
  personal contact values are included in this report.
- Request OTP returned201. An intentionally incorrect OTP returned400 and did not
  register an account. Correct OTP verification201 was followed by register201
  and authoritative GET /me200.
- Backend currently binds ConsoleSmsSender with SMS_PROVIDER=console. These are
  genuine local OTP challenge/verification requests, **not proof of SMS delivery**.
- Tickets and notifications loaded200 after authentication. Read-only DB checks
  confirmed zero records for this new customer; both screens displayed the
  expected empty states. Populated lists/read actions remain a separate test.
- Profile email was saved through PATCH /me and matched the owner's supplied email
  after reopening the form and in a read-only DB check. Date of birth and citizen
  ID were left blank rather than invented.
- Force-stop/reopen restored the authenticated profile. A subsequent APK update
  with install-r also preserved the session. No application data was cleared.
- Change password with an incorrect current password returned400
  INVALID_OLD_PASSWORD; the dialog retained its inputs. Correcting that field
  returned200 and closed the dialog. Logout204 followed by login200 using the new
  password loaded /me, tickets and notifications again. Login with the old
  password was not attempted; no passwords were extracted to automate it.

## Bug reproduced and fixed

Before this change, saving a profile immediately closed the edit form. Removing
only the device's ADB reverse mapping reproduced a network failure after the
form had already disappeared.

The profile flow now has an explicit submission status and inline error. It
retains edits on failure, blocks duplicate submission, and closes only after
server-confirmed success. It discards late responses across session changes and
rejects mismatched account identity. The modal closes when authentication is
invalidated instead of keeping the previous account's fields visible.

The OTP screen and state message now describe creation/input of a challenge;
neither claims that an SMS was delivered without provider evidence.

## Validation of the fix

- Full suite: **309 tests passed**, including five new regression tests for
  deferred profile save, error/retry, duplicate submission, session invalidation,
  identity mismatch/guest mutation guards and OTP delivery wording.
- Format: **154 files / 0 changed**; analyze: **no issues**; sandbox debug APK
  build: **PASS**. No SDK/dependency upgrade.
- Device retest on the fixed APK: offline save kept the form open, showed the
  error and retained all four fields. Restoring ADB reverse and explicitly
  retrying returned PATCH /me200, then closed the form. Session remained active.
- HTTP-fixture tests and local console OTP do not certify production SMS,
  populated ticket/notification data, a real token-expiry refresh cycle, bank
  settlement or refund processing.

Private raw XML/API traces and DB summaries remain outside Git under
`mobile-qa-evidence/ci-followup`. Only the dedicated QA customer's own profile
was updated. No reset/seed, new booking/payment or financial webhook was used.

## Review dependency

This branch is based on the unmerged PR #5. Review its account-specific delta
against `feature/seat-hold-and-countdown`; retarget to develop after the base is
integrated and rerun the required CI. The existing workflow targets develop PRs,
so local gates above must not be presented as a CI run for a stacked PR.
No merge or review-thread resolution is authorized by these test results.
