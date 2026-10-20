# PR #5 review contract follow-up

Backend [PR #39](https://github.com/quocan9999/vexgo/pull/39) is merged into
`vexgo/develop@045ba695b7ff1c3b072fe8f247af08a379cb7e68`.
Ticket/history responses now expose a numeric top-level `tripId` from the real
ticket-seat-trip relation. Mobile's existing flat ticket/booking mapping already
reads this field; no route/date-derived ID or mock fallback is introduced.

## Lead findings addressed

1. **Trip identity / real review submission:** tests now use flat ticket and
   booking HTTP payloads matching the merged contract, through real data sources,
   repository and BLoC. Missing trip identity in both legacy responses blocks the
   POST and emits no success. Booking fallback must match the requested booking.
   `HOAN_TAT` is recognized as a completed ticket status for the review UI.
2. **Unsupported review tags:** Real Mode hides tag chips and submits no tags.
   The BLoC retains only the validated server receipt (rating, comment, createdAt),
   never the original form's tag selection or timestamp. Demo tags stay local.
   Blank comments stay blank instead of generating text the user did not write.
3. **Test quality:** the old hand-built nested trip fixture has been replaced by
   a flat Backend contract fixture. A new HTTP regression suite covers valid and
   missing identities, booking mismatch, malformed review receipts, HTTP
   403/409/503, explicit retry, duplicate submit, logout during POST, and Real/Demo
   tag visibility. A response must identify the submitted trip/rating and contain
   a valid review ID/timestamp before the client marks the review as saved.

## Validation and limits

- New regression file: 18 tests passed.
- Full local Flutter suite: 322 tests passed.
- New tests use HTTP fixtures, not live customer reviews. Backend PR #39 separately
  ran the real MySQL/HTTP review-persistence regression and passed Backend CI.
- POST then GET reload is exercised. The current ticket API does **not** return
  saved reviews, so review hydration across reload/restart remains a Backend
  contract gap. Tests explicitly expect no invented review/tags after reload;
  this is not a claim of complete review read-back support. Duplicate review
  rejection remains enforced by Backend.
- This follow-up changes Mobile only and creates no real booking, review,
  payment or refund. Device review E2E is not claimed. Account changes stay in
  the separate PR #6. Reviewer verifies and resolves the three open threads.
