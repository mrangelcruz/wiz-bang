# Wiz AWS Connector - GEICO AWS Organizations
#
# Scans all accounts in AWS Organizations.
# The IAM role must be deployed to the management account with OrganizationAccountAccessRole
# or equivalent cross-account trust.

resource "wiz_aws_connector" "geico" {
  name    = var.aws_connector_name
  enabled = true

  auth_params {
    customer_role_arn = var.aws_wiz_role_arn
  }

  extra_config {
    # Scans all accounts in AWS Organizations (default behavior)
    # skip_organization_scan = false

    # Exclude specific accounts if needed
    # excluded_accounts = []

    # Exclude specific OUs if needed
    # excluded_organization_units = []
  }
}

