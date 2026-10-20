# PR #5 — three Lead findings, 19 October 2026

Changes follow the review on Mobile `c29613e` and the existing Backend
`develop@8b33925`. Backend source, migrations and environment files are unchanged.

## Changes

1. **Unknown rating:** `TripModel.rating` is nullable. Search cards and trip
   details omit the badge when no rating is supplied. Rating sorting puts unknown
   ratings after known values. Explicit fixture/API ratings remain supported.
2. **Notification delivery state:** only an explicit `category` classifies a
   notification. `type` and `trangThai` never imply a content category. Missing or
   unsupported categories are `unknown`; the screen shows the complete list and
   hides category tabs when any row lacks a category. Session and mark-read
   behavior are preserved.
3. **Guest cancellation:** the guest lookup panel exposes cancellation for an
   upcoming ticket. Opening confirmation performs another public lookup and uses
   the returned eligibility, fee and estimated refund. Confirmation sends the
   original lookup credentials and `expectedCancelFeeRate` through the existing
   public `POST /tickets/cancel`. No protected customer list or login is required.

Guest cancellation is single-flight. Loading/submission hides the boarding QR.
A changed quote requires a new confirmation; failed or unknown POST results are
reconciled by lookup without automatic mutation retry. Returned ticket identity
and cancellation status are checked. After an accepted cancellation, stale or
failed ticket reads cannot restore the paid QR. Session changes and disposal
discard late responses. The UI does not claim bank refund settlement.

Backend quote fields are required and validated rather than defaulting a missing
fee to zero. The existing authenticated cancellation flow is unchanged.

## Validation

- `test/lead_round_20261019_test.dart`: 16 regression tests through real models,
  BLoCs, repositories/data sources and widget flows, with isolated HTTP fixtures.
- Full local Flutter suite: **299 tests passed**.
- `flutter analyze --no-pub`: **no issues**.
- Local sandbox debug APK: **build passed** with `--debug --no-pub` and the
  existing public sandbox defines. CI checks on the pushed commit are recorded
  separately in the PR. Local testing does not imply a successful CI run.

These tests create no live cancellation, refund or financial transaction.
The earlier physical Android / SePay Test Mode happy path belongs to source
`c29613e`; it is not evidence that this new cancellation UI ran on a real device.
Device verification of this revision remains separate.

## Success-screen follow-up

Lead verified and resolved the three findings above at `85be8db`. The two
subsequent success-screen findings are addressed in the follow-up commit:

- The full ticket code wraps inside the available width, with a separate fixed
  copy button. Copy preserves the original code. The payment badge sits below
  the operator row so larger text also fits on a narrow screen.
- The unconditional email-delivery claim is replaced by instructions to save the
  ticket code and booking phone number for guest lookup. Neither a supplied email
  nor payment success proves mail delivery.
- Five new widget regressions cover 320/360dp, empty/provided email, full-code
  clipboard output, and multiple tickets at 150% text size on 320dp. Full local
  suite: **304 passed**; analyze: **no issues**. Initial enlarged-text regression
  exposed a 7.8px overflow in the operator/payment row; that layout was fixed
  without weakening the assertion.

Physical guest cancellation at `85be8db` was subsequently verified on Android:
ticket347/booking835 cancelled, A02 released; refund746 remains pending. This is
separate evidence from the new success-screen widget regressions. No new live
booking, payment, email delivery or bank refund is claimed for this follow-up.
Review threads remain for the reviewer to verify and resolve; no merge/release
approval is inferred.
