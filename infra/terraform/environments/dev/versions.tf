terraform {
  required_version = ">= 1.6"

  required_providers {
    btp = {
      source  = "SAP/btp"
      version = "~> 1.26" # pinned to what was actually downloaded and
      # schema-checked against while building this
      # module (v1.26.0) - bump deliberately.
    }
  }

  # Local `terraform apply` isn't the right practice for a project meant to
  # be applied via GitHub Actions from a public repo: GitHub-hosted runners
  # are ephemeral, so state has to live somewhere outside the runner, and
  # state files can contain sensitive values (XSUAA credentials output,
  # etc.) that shouldn't sit in a public git history either. HCP Terraform
  # (Terraform Cloud) is the standard, free-tier answer for exactly this
  # combination - remote state + run history + a place for
  # TF_VAR_btp_username/TF_VAR_btp_password to live as workspace
  # environment variables instead of GitHub secrets baked into a workflow
  # file. Needs a (free) HCP Terraform account + workspace created before
  # this backend can actually initialize - see this folder's README.
  cloud {
    organization = "CHANGE_ME" # your HCP Terraform org name
    workspaces {
      name = "procureiq-dev"
    }
  }
}
