# Mobile discovery UI — first UI PR

## Scope

Applies the agreed Web-inspired design to Home, city selection, search results,
date selection, filters, sorting and trip details. The booking/seat/payment,
tickets, receipts, account, notifications and chat screens are outside this PR.

The branch starts from Mobile develop `7981d22`; the separate receipt/chat PRs
are not copied into it. Web reference: develop `bc863de` and the reviewed Home
and screen proposals. Backend contracts, repositories, models, BLoC events and
business rules are unchanged.

## Design decisions

- Header red `#DC2626`, Vex white / Go amber; interaction blue `#1A56DB`, search
  and select-trip CTA orange `#FF5A1F`, white cards on `#F5F7FA`.
- `DiscoveryTheme`, colors, typography, buttons and app bars are scoped to this
  feature. Existing global AppTheme/AppColors/TextStyles remain untouched.
  Bottom-navigation label style uses the new font only while Home is active.
- Plus Jakarta Sans is bundled as a variable font with weight registrations
  400–800, including Vietnamese glyphs; no new runtime font request is needed
  by these screens. Its OFL license is included with the font.
- Home retains its header and lookup shortcut during loading/error. Search is
  shown when the existing Home BLoC has loaded its data. Retry uses the same
  existing load event. Raw transport errors are not displayed to customers.
- The search form retains city/date/round-trip/ticket-count events and the same
  navigation payload. Small screens and larger system text wrap date shortcuts
  and quantity controls instead of squeezing them into one line.
- Trip cards show supplied operator/type, route stops/times, amenities, optional
  rating, seat availability and money. Details and select-trip callbacks retain
  the same flow. Date/filter strips grow with text scale.
- Unsupported promotional banners, invented marketing/compensation claims and
  hardcoded hotline text are no longer mounted on Home. Placeholder “all” links
  with empty callbacks are omitted. No voucher catalogue is invented; voucher
  entry in the existing booking summary is outside this PR.

## Verification

Executed local checks:

- Analyzer: no issues.
- Full Flutter test suite: 333 passed (326 baseline plus 7 new tests).
- New widget tests check Home at 320dp with normal/2x text and in landscape,
  loading-error recovery, the unchanged swap/search route payload, large-text
  trip/date/filter layout with the original trip callback, and returned filter
  selections. Repository data in these tests is fixture/fake data, not E2E.
- Android debug build targets `http://127.0.0.1:4000/api/v1` for USB QA; receiving
  bank configuration is not part of this UI change.

Physical-device visual/flow results and exact-head CI are recorded in the PR
after execution. No claim of Android E2E or payment settlement follows from the
widget tests. No shared database reset/seed is needed.

## Device review checklist

Review Vietnamese text/font weights, Home header/form, city swap, quantity,
calendar, search result cards, filter apply/reset, sort selection, trip detail
and entry to the existing booking screen. Inspect the keyboard, system bars,
small display and landscape. Confirm screens outside discovery keep their prior
appearance. Dark mode redesign and SDK/dependency upgrades are not in this PR.
