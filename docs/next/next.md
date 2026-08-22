# Continuity notes — read this at the start of every session

Last updated: 2026-08-22 (end of first build session)

## Where things stand

- **`services/procurement-core` is real and working**: CAP/Node.js, CDS domain
  model (Suppliers, PurchaseRequisitions[+Items], Approvals, PurchaseOrders[+Items]),
  full submit→approve/reject workflow with threshold-based approval routing,
  RBAC via mocked auth, 9/9 Jest tests passing. Runs on SQLite, no BTP account
  needed. See `services/procurement-core/README.md` for exact run commands and
  documented limitations.
- Two real CAP framework gotchas found and fixed (both documented in that
  service's README and in `docs/concepts/03-cap-programming-model.md`):
  action name `reject` collides with `ApplicationService` base class; impl
  file must match the `.cds` file's basename (`service.js` for `service.cds`),
  not the service name.
- One real host-environment issue found and fixed: broken/stale libc++ headers
  in this Mac's Command Line Tools install, breaking any native npm module
  build (`better-sqlite3` in this case). Workaround documented in
  `docs/references/macos-native-build-toolchain.md` — **the CXXFLAGS/CPPFLAGS
  env vars in that doc need to be exported before any future `npm install`
  that involves native modules on this machine**, until the real fix (Xcode
  CLT reinstall, needs sudo + user's call) happens.
- Concept docs written so far: `01-sap-btp-fundamentals.md` (general BTP
  orientation), `03-cap-programming-model.md` (grounded in the actual
  procurement-core code). Still to write: 02 (extensibility/Clean Core),
  04-10 per the charter's coverage map — write each once the code it
  describes exists, not before.
- Local dev tool inventory confirmed already present on this machine (no setup
  needed): Node 20.19.4, `@sap/cds-dk` 9.8.4, Java 17, Docker (daemon started),
  `cf` CLI 8.18, `btp` CLI 2.106.1, Eclipse.app **with ADT plugins already
  installed**, `mbt` 1.2.45, Terraform 1.6.0, Python 3.9.15.
- No BTP account exists yet — still Vishal's action item. Not blocking further
  local-only work.
- Git: clean, staged commits per logical unit (schema+service, tests, docs,
  toolchain note) — keep doing this every session, user explicitly asked for
  visible incremental commit history as a credibility signal.

## Immediate next steps

1. **Supplier referential-integrity check** flagged as a known gap in
   procurement-core's README — worth closing before moving on, or explicitly
   deferring to a "v-next" list if we move to the next service instead.
2. **`services/supplier-master-abap`** (Phase 3 originally, but ABAP work
   needs a live BTP ABAP Environment — there's no local ABAP Cloud runtime).
   Options when picking this back up: (a) wait for the trial account and do
   this against the real ABAP Environment trial instance via Eclipse+ADT
   (already installed), or (b) start with `infra/terraform` instead since
   that also needs the account. Given "local first" instruction, consider
   pulling forward something else local-only next: `services/ai-copilot`'s
   RAG piece can be built and tested fully locally (Chroma or similar +
   Ollama + Langfuse, all local/Docker) before any BTP account exists —
   likely the better next target than waiting on ABAP/Terraform.
3. Once BTP trial account details arrive from Vishal (region + subdomain):
   unblocks `infra/terraform`, real HANA Cloud, real XSUAA, Kyma, and ABAP
   Environment work.

## Standing instructions from the user (2026-08-22 session)

- Local-first: everything must be runnable and testable locally before any
  BTP deployment is attempted. Write real code — don't describe/scaffold
  without running it.
- Set up any required tooling proactively (turned out to already be
  installed here — verify before reinstalling anything).
- Keep writing concept docs as we build, referencing the actual code where
  possible (not a hard requirement, but preferred).
- README + inline docs carry the setup/run instructions — no separate
  cmds/setup doc needed beyond that.
- Cover the **whole** SAP domain, production-grade, full capstone scope —
  do not quietly scale down to an MVP.
- Commit in clear phases/stages throughout, not one giant commit at the end.
- Don't do anything destructive to the host system (e.g. no `sudo rm -rf
  CommandLineTools` without asking) — workarounds instead, documented.
- After this project ships, a DevOps-domain-wide project is planned next —
  not started.

## Things NOT to do (carried over, still applies)

- Do not reuse or reference `career/03-sap/leverx/projects/demo-phase-3` /
  `demo-phase-4` as a foundation — it's a toy, explicitly excluded.
- Do not frame this project around any specific interview/interviewer —
  Vishal already has the EY-GDS offer; this is a general domain-mastery
  showcase, not interview prep.
