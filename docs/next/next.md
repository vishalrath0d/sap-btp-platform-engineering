# Continuity notes — read this at the start of every session

Last updated: 2026-08-22 (end of session 4 — Terraform/CI-CD built + 3-agent research sweep)

## Where things stand

**4 services, 49/49 tests passing, 36 staged commits.** procurement-core,
ai-copilot, spend-anomaly-detector (now with Feature Flags, Alert
Notification, Job Scheduling simulations), legacy-erp-gateway.

**New this session:**
- **`infra/terraform`** — full landing zone module, every resource/attribute
  name verified against the real downloaded `SAP/btp` provider v1.26.0
  schema (not memory). `terraform validate` passes. Real account details
  wired in (subdomain `4cbf0c12trial-ga`, region `us10`). **Not applied** —
  build-first-deploy-after-review per the account strategy.
- **`services/procurement-core/mta.yaml`** — verified with a REAL `mbt
  build` end to end (not just syntax-checked): generates real HDI
  `.hdbtable`/`.hdbtabledata` artifacts, produces an actual `.mtar`.
  Needed a `[production]` cds profile (`db.kind: hana`, `auth.kind:
  xsuaa`) + `@cap-js/hana` + `@sap/xssec` deps before `cds build` would
  emit `gen/db` at all — a real, non-obvious finding.
- **`xs-security.json`**, **`mtaext-dev.mtaext`** (also mbt-verified) — real
  XSUAA descriptor matching the local mocked-auth roles exactly.
- **Piper (`.pipeline/config.yml` + `Jenkinsfile`)**, **GitHub Actions**
  (`.github/workflows/procurement-core-ci.yml` — test + build-mta jobs
  are real and would run if pushed; deploy-dev is complete but gated
  `if: false` behind a required-reviewers environment), **SAP CI/CD
  service** (documented, cockpit-configured, not a repo file) — all three
  tracks documented in `ci-cd/README.md` with the real reason the actual
  files live with the app / at repo root, not in `ci-cd/`.

## MAJOR backlog from 3 parallel research agents this session (not yet incorporated — prioritize next)

Three agents swept: (1) EY-GDS interview prep, (2) SAP-direct + LeverX
interview prep, (3) Discovery Center missions/learning journeys/GitHub
companion repos. Consolidated, deduplicated findings below, roughly
prioritized by cheapness × signal:

### Cheap doc additions (do these first — no new services needed)
1. **Cite RA0005 "Generative AI on SAP BTP"** (github.com/SAP/architecture-center) explicitly in `09-ai-on-btp.md` and `ai-copilot`'s README — it's SAP's own official reference architecture for almost exactly `ai-copilot`'s design (CAP + HANA Vector Engine + Generative AI Hub). Adapt its diagram as the free-tier-mode architecture diagram.
2. **Cite RA0033 "SAP Document AI"** as the SAP-native alternative to `ai-copilot`'s flat-corpus-files ingestion, one paragraph.
3. **Dynatrace vs Prometheus/Grafana note** in `observability.md` — Dynatrace is what SAP's own internal DLM team and EY's real client landscapes actually run, currently zero mention.
4. **ATC (ABAP Test Cockpit) + AUnit as a named quality gate, with the exemption-workflow concept**, in `04-abap-cloud-and-rap.md` or `08-devops-toolchain.md` — real SAP DevOps mechanism, currently absent.
5. **SonarQube + BlackDuck as named Piper steps** (`sonarExecuteScan`, `whitesourceExecuteScan`) in `08-devops-toolchain.md` — currently Piper only mentioned generically. Real ABAP pipeline config examples for `atc-static`/`atc-transient` variants confirmed via `SAP-samples/abap-platform-ci-cd-samples` (see research report in session transcript for exact YAML).
6. **CALMS framework** — one paragraph near the DevOps toolchain doc; a real framework SAP's own BTP interview material leans on repeatedly.
7. **Short, explicitly-labeled compliance design note** (NISPG/DPDP Act/CERT-In's 6-hour incident-reporting SLA) in the connectivity or SRE doc — design-awareness only, matching the existing SoD/GRC and Digital Access licensing pattern. **Do not build/simulate sovereign-cloud infrastructure** — the research agent was explicit that this would overstate scope.
8. **Cite the Guidance Framework's named methodologies** as explicit rationale sources: Application Extension Methodology in `02-extensibility-and-clean-core.md`, Integration Solution Advisory Methodology in `06-integration-patterns.md`.
9. **HA/DR design note** in `sre-practices.md` (currently incident-focused, not availability-design-focused) — named gap from "Operating SAP Business Technology Platform" learning journey unit 7.
10. **Cloud Identity Services vs XSUAA distinction** in `05-security-xsuaa-destinations.md` — XSUAA is app-level, Cloud Identity Services is tenant-level IdP/SSO, currently only XSUAA covered.
11. **Kyma Connectivity/Transparent Proxy nuance** — CF has App Router for Destination-service lookups by default, Kyma doesn't; a real "silent failure" trap per EY prep docs. Add to `11-connectivity-cloud-connector.md`.
12. **`org.cloudfoundry.existing-service` vs `managed-service`** MTA resource-type distinction (central-XSUAA-instance pattern across multiple apps) — small, cheap, add to whatever doc covers `mta.yaml`.
13. **Adopt SAP's BTP Solution Diagrams icon/shape library** (sap.github.io/btp-solution-diagrams) for any future architecture diagrams — pure styling, reads as "knows SAP's visual conventions."
14. **Istio/service-mesh short note** wherever `spend-anomaly-detector`'s Kyma deployment gets documented (Kyma runtime learning journey unit 5) — mTLS-by-default, traffic policy at the mesh layer.

### Real, concrete technical corrections/additions (medium effort)
15. **Kyma APIRule syntax is v2** (`gateway.kyma-project.io/v2`), NOT v1beta1 — confirmed via SAP's live `kyma-runtime-samples` repo. Use v2 when `spend-anomaly-detector`'s Kyma YAML actually gets written (still backlog, needs account).
16. **Deeper CAP multitenancy (MTX) mechanics** for `12-multitenancy-and-saas.md` when built: `saas-registry` + `service-manager` MTA resources, the `zid` JWT claim as tenant ID, subscription-time (not deploy-time) HDI container provisioning. Real companion repo: `SAP-samples/btp-side-by-side-extension-learning-journey` (6-step branch-per-exercise pattern) and the "Develop a Multitenant CAP Application" mission (uses the Incident Management sample app).
17. **`@sap-ai-sdk/foundation-models`** — the real Node.js package name for AI Core/Generative AI Hub wiring, plus the pattern of an AI Core service key or a `GENERATIVE_AI_HUB`-named Destination the SDK auto-discovers. Use when the AI Core free-tier upgrade path for `ai-copilot` actually gets built. Real code pattern also confirmed via `SAP-samples/cap-ai-vector-engine-sample`: `cds.connect.to('cap-llm-plugin')`, `cap-llm-plugin` npm package, `getRagResponse`/`getEmbedding`/`similaritySearch` methods — full package.json + service.js pattern in session transcript.
18. **`SAP-samples/btp-genai-starter-kit`** — literally Terraform-provisions AI Core (extended plan) + HANA Vector Engine together; closest existing SAP sample to this project's own Terraform+AI-Core-upgrade combination. Worth a direct look when building that phase. (Archived repo, frozen snapshot.)
19. **e2e test stage in Piper** mirroring `SAP-archive/devops-cap-pipeline-openSAP`'s pattern: UIVeri5 tests wired into the pipeline after deploy, switchable between local `localhost:4004` and the deployed URL. Currently `.pipeline/config.yml` has no e2e stage.
20. **Real bugs to watch for when actually deploying** (from leverx troubleshooting notes, verbatim in session transcript): (a) a missing/duplicate `ID` in an `.mtaext` fails `cf deploy` at validation — already handled correctly in `mtaext-dev.mtaext`; (b) `cf push` with a manual manifest AFTER an MTA deploy is set up poisons the app's CF process command (MTA update doesn't reset it) — **never `cf push` procurement-core manually once MTA deploy is used once**; (c) SQLite-on-CF needs `npm_config_build_from_source: true` + explicit `NODE_ENV=development` override to seed in-memory data — not relevant to us since we deploy against real HANA Cloud, not in-memory SQLite, but worth knowing if ever debugging a "no such table" error on CF.
21. **`VCAP_SERVICES` xsuaa binding's `xsappname` gets suffixed `!tNNNNNN` at runtime** — differs from the bare `xsappname` in `xs-security.json`. This is exactly why `role_collections.tf` is two-phase (see that file's comments) — now doubly confirmed by real `VCAP_SERVICES` inspection, not just Terraform provider knowledge.

### Explicitly NOT to build (already decided, don't re-litigate)
- Sovereign-cloud infrastructure simulation (NISPG/DPDP/CERT-In) — design note only, per research agent's explicit warning about overstating scope for a role that never reached interview.
- I7P/Correction Workbench and other SAP-internal-only tool specifics from leverx prep — too client-instance-specific to responsibly reference.
- Splunk as a built integration — name-drop in the Dynatrace/observability doc note (#3 above) is enough; not a service to stand up.

## Immediate next steps (still locally-buildable, no account needed)

1. Work through the "cheap doc additions" list above (#1-14) — highest signal-to-effort ratio, matches this project's established pattern of small, well-cited additions.
2. Remaining backlog from session 3 not yet done: MTX/multitenancy (now has much better real-pattern guidance, see #16), API Management layer, Document Management Service simulation, Workflow Management (BPMN) design note.
3. Remaining original concept docs still not written: `02`, `04` (now with ATC/AUnit content), `05` (now with Cloud Identity Services + Kyma Connectivity content), `06` (now with Integration Solution Advisory Methodology citation), `07`, `08` (now with SonarQube/BlackDuck/CALMS content), `09` (now with RA0005 citation), `10` (now with Digital Access + NISPG/DPDP note).

## Once BTP account access is actually usable (Vishal needs to log in / provide credentials)

1. `terraform plan` against the real account — expected to surface any wrong `service_name`/`plan_name` in `entitlements.tf`, documented as the real verification step.
2. Real XSUAA deploy → two-phase `role_collections.tf` apply.
3. ABAP Cloud/RAP module via Eclipse+ADT (already installed).
4. Real Piper/GitHub Actions deploy runs.
5. `transport/cloud-transport-management`, `services/integration-flow`.

## Known housekeeping

- `mbt build` and any native npm install still need the CXXFLAGS/CPPFLAGS
  workaround from `docs/references/macos-native-build-toolchain.md`.
- Terraform's `.terraform.lock.hcl` IS committed (fixed a gitignore mistake
  this session); `.terraform/` cache dir is not.

## Things NOT to do (carried over, still applies)

- Do not reuse `career/03-sap/leverx/projects/demo-phase-3`/`demo-phase-4`
  as a foundation for code — it's fine as a reference for real syntax
  patterns (used extensively this session), never as copied source.
- Do not frame this project around any specific interview/interviewer.
- User explicitly said "just build it, don't deploy yet" — do not run
  `terraform apply`, `cf push`, `cf deploy`, or enable the GitHub Actions
  deploy job without an explicit go-ahead.
