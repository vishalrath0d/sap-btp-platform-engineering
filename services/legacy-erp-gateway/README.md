# legacy-erp-gateway

A mock "on-prem" legacy supplier master system — the other half of
`procurement-core`'s `syncLegacySuppliers` action and
`docs/concepts/11-connectivity-cloud-connector.md`. Read that concept doc
first for the full Destination-service/Cloud-Connector story this service
plays a role in.

## Why it looks the way it does

Deliberately **not** shaped like a clean BTP/CAP service — real legacy
on-prem systems are exactly this: cryptic field names, single-letter status
codes, no OData/CDS conventions:

```json
{
  "SUPPLIER_ID": "LEG-001",
  "COMPANY_NAME": "Meridian Fabrication Works",
  "CTRY_CD": "US",
  "TAX_REG_NO": "US-TAX-778",
  "CONTACT_EMAIL": "ap@meridianfab.example",
  "RISK_CD": "L",
  "REC_STATUS": "A"
}
```

`procurement-core`'s `srv/lib/legacy-supplier-mapper.js` translates this
into the clean domain model (`riskRating: LOW`, `status: ACTIVE`, etc.) —
that translation is real integration-developer work worth testing on its
own (8 unit tests, no network needed), not incidental plumbing to skip past.

## Run it

```bash
npm install
npm start   # listens on :4007
```

```bash
curl http://localhost:4007/legacy/suppliers
```

### Tests

```bash
npm test
```

2/2 passing — confirms the mock actually returns the legacy shape (not the
clean domain shape), so the mapping-layer tests in `procurement-core` stay
honest about what they're translating from.

## Known limitations

- Static, read-only data (`data/suppliers.json`, 5 records) — no write
  operations, no pagination, no simulated legacy-system flakiness (a real
  legacy system integration would also need timeout/retry handling, which
  `procurement-core`'s sync action doesn't yet exercise since this mock is
  always fast and always up).
