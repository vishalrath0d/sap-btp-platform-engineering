terraform {
  required_version = ">= 1.6" # matches what's actually been used to init/validate
                                # this module throughout (tfenv-managed 1.6.0 locally).
                                # The workspace's own "Terraform v1.15.9" setting in the
                                # HCP UI doesn't bind us here - that setting only matters
                                # for HCP Terraform's own remote execution, and this
                                # workspace uses Local execution mode (GitHub Actions runs
                                # the actual CLI), so it never applies.

  # Deliberately empty: organization and workspace name are supplied via
  # TF_CLOUD_ORGANIZATION and TF_WORKSPACE environment variables instead
  # of hardcoded here - confirmed against HashiCorp's own docs
  # (developer.hashicorp.com/terraform/cli/cloud/settings): when a `cloud`
  # block argument is omitted, Terraform reads the matching env var; the
  # workspace must already exist (HCP Terraform won't create one from the
  # env var alone). This lets CI switch environments (procureiq-dev,
  # procureiq-qa, procureiq-prod) just by setting TF_WORKSPACE differently
  # per job, with zero changes to this file - see
  # .github/workflows/terraform-*.yml.
  #
  # (Earlier version of this file used the legacy `backend "remote"` block
  # with -backend-config overrides, modeled on how the reference
  # sm-infraforge/langfuse project parameterizes its S3 backend. Switched
  # to `cloud {}` once building this out revealed two things: HCP
  # Terraform's own UI recommends `cloud` over `backend "remote"` now, and
  # workspaces with Local execution mode - which this project uses,
  # deliberately, so GitHub Actions runs plan/apply rather than HCP
  # Terraform's own remote execution - don't expose the Variables UI
  # `backend "remote"`'s setup implied would be available.)
  cloud {}

  required_providers {
    btp = {
      source  = "SAP/btp"
      version = "~> 1.26" # pinned to what was actually downloaded and
                            # schema-checked against while building this
                            # module (v1.26.0) - bump deliberately.
    }
  }
}
