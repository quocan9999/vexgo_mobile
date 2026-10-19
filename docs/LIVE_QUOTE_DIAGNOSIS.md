# Live quote 404 — confirmed data cause

Audited Backend: `8b339250a95b6825cef591b1d10ae537ba1068f4`. Diagnosis used explicit read-only MySQL transactions; no fare or source changes were made during investigation.

| Existing future trip | Operator / route / vehicle type | Fare rows for that operator | Seat state at inspection |
|---|---|---:|---|
| 149, 2099-01-01 | 69 / 68 / 69 | 0 | 3236 already booked |
| 187, 2099-12-01 | 107 / 97 / 99 | 0 | 3294, 3295 available |

The shared DB contains 219 trips, exactly these two future trips, and zero future trips matching an active applicable fare. All 33 existing active fare rows belong to operators 1, 2 or 3. Thus no existing valid future alternative can be selected for a successful quote in this DB snapshot.

`BookingsService.getBookingQuote` requires the exact operator/route/vehicle-type tuple and fare date validity. With no fare for either operator, it throws; the standard exception filter produces the captured `404 NOT_FOUND`. This is missing data for the test trips, not proof that Mobile needs to bypass price validation, change endpoints, or synthesize a price.

## Approved test-data proposal

The user explicitly approved creating one local QA trip through the existing authenticated API, subject to current preflight and tenant permissions:

```json
{
  "code": "QA-QUOTE-20261020-001",
  "routeId": 10,
  "vehicleId": 14,
  "departureDate": "2026-10-20",
  "departureTime": "08:00:00",
  "acceptsShipments": false
}
```

Tenant 3 has existing active fare **29**, matching route 10 and vehicle type 8, **260000.00 VND**, valid from 2026-09-01 without an end date. Vehicle 14 has 22 physical seats. No price is invented or copied across tenants. The proposed trip adds one schedule and its real inventory; old trips 149/187, fare 29 and all other business records remain unchanged.

Execution must recheck future date, unique code, tenant ownership, permissions, route/vehicle/fare status and schedule conflict. It must use an existing authorized principal, never create roles/accounts or guess credentials. If no usable principal or allowed API runtime is available, creation remains blocked rather than using direct SQL inserts.

Acceptance after successful creation: read actual trip/inventory and quote one/two returned available seat IDs, recording Backend totals of 260000.00 / 520000.00 only if actually returned. No booking, payment, bank callback or promotion success is implied. Leave the approved QA trip available for later device testing; if cleanup is required and there are no active bookings/shipments, use the existing trip cancellation API and retain audit history.

This file records the diagnosis and approved proposal, not an execution result. Actual creation/quote evidence and CI run links are reported in the PR follow-up after execution. GitNexus MCP was unavailable and external-index bootstrap did not complete; no completed graph check is claimed. Backend implementation was not edited.
