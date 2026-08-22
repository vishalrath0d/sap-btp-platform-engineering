# environments/qa (stub)

Deliberately not a working root module yet. The BTP **trial** provides
exactly one subaccount total — there is no second subaccount to point a
`qa` environment at. A real `qa` environment needs a paid (or free-tier
PAYG) landscape with at least two subaccounts, or a directory with
subaccounts-per-environment under it.

## What this becomes once that exists

The same shape as `environments/dev` — a `main.tf` composing
`../../modules/*` with `qa`-specific variables (a different
`subaccount_subdomain`, `name`/`org_name` suffixes) — the modules
themselves need no changes, only a new root module instantiating them
against a different subaccount. `transport/cloud-transport-management`'s
Dev→QA→Prod promotion (also scoped, also account-gated) is what this
environment exists to receive.

Not scaffolded further than this README to avoid implying a working
environment exists when it can't be applied against anything real yet.
