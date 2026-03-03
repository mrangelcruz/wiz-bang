# =============================================================================
# Wiz Provider Credentials (sensitive - set via .env.wiz)
# =============================================================================

variable "wiz_client_id" {
  description = "Wiz service account Client ID for the production tenant."
  type        = string
  sensitive   = true
}

variable "wiz_client_secret" {
  description = "Wiz service account Client Secret for the production tenant."
  type        = string
  sensitive   = true
}

# =============================================================================
# AWS Connector Variables (set via terraform.tfvars)
# =============================================================================

variable "aws_connector_name" {
  description = "Name of the AWS connector in Wiz."
  type        = string
}

variable "aws_wiz_role_arn" {
  description = "ARN of the IAM role Wiz assumes in the AWS Organizations management account."
  type        = string
}

# =============================================================================
# GCP Connector Variables (set via terraform.tfvars)
# =============================================================================

variable "gcp_connector_name" {
  description = "Name of the GCP connector in Wiz."
  type        = string
}

variable "gcp_organization_id" {
  description = "GCP Organization ID (numeric)."
  type        = string
}

# =============================================================================
# Integration Variables (set via terraform.tfvars and .env.wiz)
# =============================================================================

variable "slack_integration_name" {
  description = "Name of the Slack integration in Wiz."
  type        = string
}

variable "slack_bot_token" {
  description = "Slack Bot OAuth token for Wiz integration."
  type        = string
  sensitive   = true
}

variable "ado_integration_name" {
  description = "Name of the Azure DevOps integration in Wiz."
  type        = string
}

variable "ado_webhook_url" {
  description = "Azure DevOps webhook URL for Wiz integration."
  type        = string
}

# =============================================================================
# Automation Rule Variables (set via terraform.tfvars)
# =============================================================================

variable "automation_slack_critical_name" {
  description = "Name of the Slack automation rule for critical issues."
  type        = string
}

variable "slack_channel_critical_issues" {
  description = "Slack channel for critical issue notifications."
  type        = string
}

variable "slack_note_critical_issues" {
  description = "Note included in Slack message for critical issues."
  type        = string
  default     = ""
}

