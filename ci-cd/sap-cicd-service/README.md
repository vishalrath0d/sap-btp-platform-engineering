# SAP Continuous Integration and Delivery service

The "no infrastructure to host" option — a managed, BTP-hosted CI/CD
service, configured through the cockpit UI rather than a file in this repo.
Same Piper engine underneath as the Jenkins track; the *config* is entered
through a job editor, but it reads the same `.pipeline/config.yml` this
project already has at the repo root (shared by both `Jenkinsfile.cf` and
`Jenkinsfile.kyma` — see `ci-cd/piper/README.md`) — nothing to duplicate
here.

## The real setup sequence

(confirmed against SAP's own "Setting Up Continuous Integration and
Delivery (CI/CD) Service" mission — not guessed):

1. Verify CI/CD service entitlements and existing instances
2. Activate the CI/CD service subscription
3. Access the CI/CD application interface
4. Create credentials for GitHub and BTP authentication
5. Add this GitHub repository to the CI/CD system
6. Generate and configure webhook credentials
7. Set up the webhook in this repo's GitHub settings
8. Create a CI/CD job via the Job Editor — an SAP Fiori pipeline template,
   or a custom YAML-based definition for a project with subfolders like
   this monorepo (one job per service for test, mirroring the GitHub
   Actions/Jenkins tracks' own per-service test / per-runtime deploy split)
9. Deployment verification in the subaccount's HTML5 Applications section

## Why this project doesn't use this as its primary CI

GitHub Actions was chosen as the actual running CI (see
`ci-cd/github-actions/README.md`) because it needs zero BTP-side setup to
develop and test locally, and doesn't consume the trial's limited service
instance count. The SAP CI/CD service is documented here because it's a
real, named part of the SAP DevOps toolchain (unit 4/8 of SAP's own
"Discovering DevOps with SAP BTP" learning journey covers it directly) and
a real SAP shop would reasonably choose it over self-hosted Jenkins
specifically to avoid running Jenkins infrastructure — worth knowing how
and why to choose it, even though this project's own pipeline runs
elsewhere.

## Not yet set up

Steps 2–9 above all need the live BTP account and haven't been done —
step 1 (checking entitlements) is the first thing to actually try once
account review is complete, if this track is ever activated for real
alongside GitHub Actions.
