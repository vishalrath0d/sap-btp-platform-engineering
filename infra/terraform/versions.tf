# This backend configuration is a TEMPLATE ONLY - CI overrides it via
# `-backend-config` flags at `terraform init` time, exactly the pattern
# used in the real sm-infraforge/langfuse project (see its backend.tf and
# jenkins-shared-library's terraformInit.groovy): one shared backend block,
# parameterized per environment at init, not duplicated per-environment
# `.tf` files.
#
# HCP Terraform's classic `remote` backend type (not the newer `cloud`
# block, which doesn't support -backend-config overrides the same way)
# supports exactly this: `organization` stays fixed, `workspaces.name` is
# what CI overrides per environment - so `dev`/`qa`/`prod` map to separate
# HCP Terraform workspaces (`procureiq-dev`, `procureiq-qa`,
# `procureiq-prod`), the direct HCP Terraform equivalent of the reference
# project's S3 key-namespacing (`{project}/{environment}/terraform.tfstate`)
# - a workspace *is* HCP Terraform's state-isolation unit, there's no
# separate "key inside one workspace" concept the way S3 has.
terraform {
  required_version = ">= 1.6"

  backend "remote" {
    organization = "CHANGE_ME" # overridden by CI - see .github/workflows/terraform-*.yml
    workspaces {
      name = "PLACEHOLDER" # CI passes -backend-config="workspaces.name=procureiq-<env>"
    }
  }

  required_providers {
    btp = {
      source  = "SAP/btp"
      version = "~> 1.26" # pinned to what was actually downloaded and
      # schema-checked against while building this
      # module (v1.26.0) - bump deliberately.
    }
  }
}
