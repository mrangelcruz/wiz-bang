# =============================================================================
# DV Environment - WIZ Terraform Variables
# =============================================================================

# =============================================================================
# AWS Connector Variables
# =============================================================================
aws_connector_name = "GEICO AWS Dev"
aws_wiz_role_arn   = "arn:aws:iam::938436319834:role/WizAccess-Role"

# =============================================================================
# GCP Connector Variables
# =============================================================================
gcp_connector_name  = "GEICO GCP Dev"
gcp_organization_id = "735813871839" # Same GCP org as prod for now

# =============================================================================
# Integration Variables
# =============================================================================
slack_integration_name = "GEICO Slack Dev"
ado_integration_name   = "GEICO Azure DevOps Dev"
ado_webhook_url        = "https://dev.azure.com/GEICO/..."

# =============================================================================
# Automation Rule Variables
# =============================================================================
automation_slack_critical_name = "Dev: Slack Notification for Critical Issues"
slack_channel_critical_issues  = "#team-cloudsec-dev"
slack_note_critical_issues     = ":warning: Dev Environment - Critical Issue Detected :warning:"

