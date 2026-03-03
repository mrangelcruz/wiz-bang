# Wiz GCP Connector - GEICO GCP Organization
#
# Scans all projects in the GCP Organization.
# Requires Wiz service account with appropriate IAM permissions in GCP.

resource "wiz_gcp_connector" "geico" {
  name    = var.gcp_connector_name
  enabled = true

  auth_params {
    is_managed_identity = true
    organization_id     = var.gcp_organization_id
  }

  extra_config {
    # Exclude specific projects if needed
    # excluded_projects = []

    # Exclude specific folders if needed
    # excluded_folders = []

    # Or include only specific folders
    # included_folders = []
  }
}

