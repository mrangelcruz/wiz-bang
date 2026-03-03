# Wiz Integrations - GEICO
#
# Reusable connections between Wiz and third-party platforms.
# Used by automation rules and actions.

# =============================================================================
# Slack Integration
# https://docs.wiz.io/docs/slackbot-integration#define-a-slack-app-for-the-wiz-bot
# =============================================================================

resource "wiz_integration" "slack" {
  name = var.slack_integration_name
  type = "SLACK_BOT"

  params {
    slack_bot {
      token = var.slack_bot_token
    }
  }
}

# =============================================================================
# Azure DevOps Integration (Webhook)
# https://docs.wiz.io/docs/azure-devops-integration
# =============================================================================

resource "wiz_integration" "ado" {
  name = var.ado_integration_name
  type = "WEBHOOK"

  params {
    webhook {
      url = var.ado_webhook_url

      # Optional: Add authorization if required
      # authorization {
      #   token = var.ado_webhook_token
      # }

      # Optional: Custom headers
      # headers {
      #   key   = "X-Custom-Header"
      #   value = "value"
      # }
    }
  }
}

