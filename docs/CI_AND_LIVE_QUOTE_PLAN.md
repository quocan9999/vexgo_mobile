# CI and live quote follow-up — PR #5

Baseline: Mobile `461b7d22a5f0b3bce3ba7fbf1da19d819b475f0a`, clean working tree; Backend `8b339250a95b6825cef591b1d10ae537ba1068f4`, existing untracked seed script preserved. Lead resolved all six old threads but did not approve merge. User authorized starting independent CI and investigating live quote 404. This is the pre-execution plan; subsequent actual CI/data results are recorded in the PR follow-up, not inferred from these planning states.

| Task | Owner | Scope / dependency | Acceptance | Priority | Status |
|---|---|---|---|---|---|
| CI-01 | orchestrator | Mobile `.github/workflows`, CI documentation; exact existing Flutter 3.38.7 / Dart 3.10.7 and Java 17 | PR-head checkout; read-only token; locked dependencies; format/analyze/test/debug APK; immutable artifact with source SHA/checksum; no merge/deploy or secrets | P1 | IN_PROGRESS |
| FARE-01 | api-architect | Backend/DB read-only diagnosis, source and actual trip/fare evidence | Identify proven cause or explicit uncertainty; no invented price, seed/reset or API bypass; prepare concrete proposal before any data changes | P1 | IN_PROGRESS |
| SEC-CI-01 | security reviewer | Read-only workflow/security review | Correct PR event/ref, minimal permissions, no privileged target event or secret exposure; failure remains failure | P1 | TODO |
| QA-CI-01 | QA | Workflow validation + actual GitHub Actions run on pushed SHA | Record actual independent statuses and artifact; do not substitute local PASS for remote CI | P1 | TODO |

No Backend implementation, production provider, schema, dependency upgrade or business-price change is authorized by this plan. If data needs configuration, present actual existing values, affected records and rollback before requesting the required business decision. Existing local API startup was policy-blocked; do not bypass that restriction.

Follow-up decision: after the read-only diagnosis found no fares for either future trip, the user explicitly approved one QA trip on 2026-10-20 at 08:00, tenant 3 / route 10 / vehicle 14, reusing fare 29 at 260000.00 VND. See [LIVE_QUOTE_DIAGNOSIS.md](LIVE_QUOTE_DIAGNOSIS.md). No new price, seed/reset, booking or payment is authorized by that approval.

CI public receiving-bank fields may be supplied through repository variables only; absence does not create a demo account or successful payment. The debug artifact must disclose that its checkout/payment is still subject to Backend configuration and live E2E. A successful CI run is evidence of software gates, not bank settlement or device E2E.
