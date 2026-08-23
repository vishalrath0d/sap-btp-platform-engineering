# transport/cloud-transport-management

**SAP Cloud Transport Management (CTMS)** — the multi-environment
promotion layer this project's own `PROJECT_CHARTER.md` scope has called
for since session 1 ("Multi-environment promotion (Dev → QA → Prod) via
Cloud Transport Management"). Reclassified this session from
"account-gated" to "next in the provisioning queue" — see
`PROJECT_CHARTER.md`'s "Scope expansion (session 7)" section — since CTMS
is genuinely settable up on this project's existing trial subaccount (a
subscription + a service instance/key + the Landscape Wizard), not a
separate specialized account.

## The real, scaled-down topology this project actually has

Real CTMS topologies typically route between **separate subaccounts**
(dev subaccount → qa subaccount → prod subaccount). This project's trial
provides **one** real subaccount (`infra/terraform/README.md`'s own
"Known limitations" section states this plainly) — so the honest,
structurally-real demonstration of the same mechanism uses **Cloud
Foundry spaces within that one subaccount** as the transport nodes
instead: `dev`, `qa` (not yet real — see `infra/terraform/environments/
qa/terraform.tfvars`), `prod` (same). CTMS itself doesn't care whether a
node's target is a space in the same subaccount or a space in a different
one — the promotion mechanism (upload an `.mtar`, CTMS deploys it to the
next node's target) is identical either way. This is a smaller
*instance* of the real pattern, not a different one.

## Files

| File | What it is |
|---|---|
| `nodes-routes.json` | The transport landscape definition — three nodes (DEV/QA/PROD) and two routes connecting them (DEV→QA, QA→PROD), shaped like what CTMS's own REST API / Landscape Wizard accepts. `dev`'s target is real (matches the CF org/space `infra/terraform` provisions); `qa`/`prod` targets are placeholders, same honesty level their own `.tfvars` stubs already carry. |
| `../../services/procurement-core/mtaext-qa.mtaext`, `mtaext-prod.mtaext` | The environment-specific `.mtaext` overrides each promotion step would apply — `mtaext-dev.mtaext` already existed; these two are new this session, mirroring its shape (see each file's own comment for the "prod not usable yet" honesty note). |

## How this wires into CI/CD once nodes are real

`.pipeline/config.yml` (repo root, shared by both `Jenkinsfile.cf` and
`Jenkinsfile.kyma`) already has a `tmsUpload` step commented, not deleted,
with the real parameter shape (`credentialsId`, `nodeName`,
`customDescription` — verified against `SAP/jenkins-library`'s
`tmsUpload.yaml` step metadata while building this project originally).
Once `nodes-routes.json`'s DEV node is real, uncommenting that step and
adding it as a stage in `Jenkinsfile.cf` *after* `mtaBuild` and *before*
(or instead of) the direct `cloudFoundryDeploy` call turns this from "the
CI pipeline pushes straight to one space" into "the CI pipeline uploads
to CTMS, which then promotes through the real DEV→QA→PROD route" — the
actual real-world promotion path this project's account strategy has
been working toward since `PROJECT_CHARTER.md`'s original scope.

## Not yet done

- The CTMS subscription itself, and generating its service key — the
  first concrete step once `terraform apply`'s review is complete (same
  gate everything else provisioning-related in this project waits on).
- Wiring `tmsUpload` into `Jenkinsfile.cf` for real (currently only
  commented in the shared config, not called from either Jenkinsfile).
- QA/PROD as real CF spaces/subaccounts — genuinely blocked on the trial's
  single-subaccount limit, same as everywhere else this project states it.
