terraform {
  required_version = ">= 1.6"

  required_providers {
    btp = {
      source  = "SAP/btp"
      version = "~> 1.26" # pinned to what was actually downloaded and schema-checked
      # against during this project's build (v1.26.0) - bump
      # deliberately, not silently, since Terraform provider
      # schemas do change resource attributes between versions.
    }
  }
}
