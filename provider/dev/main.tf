# Development / local testing configuration.
# Used with dev_overrides in ~/.terraformrc — no registry or Artifactory needed.
#
# To use:
#   1. Add dev_overrides to ~/.terraformrc (see provider/dev/README note below)
#   2. source .env.wiz
#   3. make install  (or install-linux on Ubuntu)
#   4. terraform -chdir=provider/dev plan

variable "wiz_client_id" {
  description = "Wiz service account Client ID."
  type        = string
  sensitive   = true
}

variable "wiz_client_secret" {
  description = "Wiz service account Client Secret."
  type        = string
  sensitive   = true
}

variable "wiz_api_url" {
  description = "Wiz GraphQL API URL."
  type        = string
  default     = "https://api.us9.app.wiz.io/graphql"
}

# Placeholder — replace with wiz-azure_azure_connector once resource is implemented.
# output "provider_version" {
#   value = provider::wiz-azure.version
# }
