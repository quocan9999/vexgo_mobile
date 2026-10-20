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

- Review regression file: 22 tests passed after the readback follow-up below.
- Full local Flutter suite: 326 tests passed.
- New tests use HTTP fixtures, not live customer reviews. Backend PR #39 separately
  ran the real MySQL/HTTP review-persistence regression and passed Backend CI.
- The initial follow-up documented review loss after reload. That expectation was
  insufficient UX and is replaced: the companion Backend readback change returns
  persisted own-customer/per-trip reviews in authenticated ticket list/detail.
  Tests now require the accepted review to survive refresh and screen reopening,
  with the badge retained and submit CTA suppressed. Backend readback must be
  deployed before merging this Mobile follow-up.
- This follow-up changes Mobile only and creates no real booking, review,
  payment or refund. Device review E2E is not claimed. Account changes stay in
  the separate PR #6. Reviewer verifies and resolves outstanding threads.

## Completed-ticket detail and readback follow-up

Depends on Backend [PR #40](https://github.com/quocan9999/vexgo/pull/40),
`f024217`: deploy its authenticated ticket review readback before Mobile merge.

- Model and TicketReadCubit share a supported-status parser including `HOAN_TAT`.
  Unknown states still fail closed in detail reads.
- Server review hydration uses the same strict parser as POST receipts. Invalid
  identity, rating or timestamp cannot silently become an unreviewed ticket.
- One accepted receipt updates current tickets for the trip. Already reviewed
  tickets reject local duplicate submit clearly; Backend enforces the rule across
  sessions. Unsupported tags stay absent.
- A real datasource/repository/Cubit/detail widget regression opens `HOAN_TAT`,
  submits, observes automatic refresh, manually refreshes, reopens detail and
  checks the list badge. The review stays and another submit is suppressed.
  Multiple seats and malformed readback are separate regressions. HTTP fixtures
  are not claimed as physical-device E2E.
