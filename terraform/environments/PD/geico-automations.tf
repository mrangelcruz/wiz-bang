

# Wiz Automation Rules - GEICO
#
# If-this-then-that rules that trigger actions when conditions are met.

# =============================================================================
# Slack Notification for Critical Issues
# =============================================================================

resource "wiz_automation_rule" "slack_critical_issues" {
  name        = var.automation_slack_critical_name
  description = "Sends Slack notification when a critical severity risk issue is created."
  enabled     = true

  # Trigger: When a Risk Issue is Created
  trigger_source = "ISSUES"
  trigger_type   = ["CREATED"]

  # Filter: Severity equals Critical
  filters = jsonencode({
    severity = ["CRITICAL"]
  })

  # Scope: All Projects (no project_id specified)

  # Action: Send Slack notification
  actions {
    integration_id = wiz_integration.slack.id
    type           = "SLACK_BOT"

    params {
      slack_bot {
        channel = var.slack_channel_critical_issues
        note    = var.slack_note_critical_issues
      }
    }
  }
}

