# =============================================================================
# AWS Connector
# =============================================================================

aws_connector_name = "GEICO AWS"
aws_wiz_role_arn   = "arn:aws:iam::343497816152:role/WizAccess-Role"

# =============================================================================
# GCP Connector
# =============================================================================

gcp_connector_name  = "GEICO GCP"
gcp_organization_id = "735813871839"

# =============================================================================
# Integrations
# =============================================================================

slack_integration_name = "GEICO Slack"
ado_integration_name   = "GEICO Azure DevOps"
ado_webhook_url        = "https://dev.azure.com/GEICO/..."

# =============================================================================
# Automation Rules
# =============================================================================

automation_slack_critical_name = "Slack Notification for Critical Issues"
slack_channel_critical_issues  = "#team-cloudsec"
slack_note_critical_issues     = ":alert: Critical Issue, notifying @cloud-security :alert:"


