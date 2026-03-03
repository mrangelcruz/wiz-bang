

#!/usr/bin/env bash
#
# import.sh - Import existing Wiz resources into Terraform state
#
# Run this script ONCE when setting up Terraform for the first time,
# or when adding new resources that already exist in the Wiz console.
#
# Prerequisites:
#   - Terraform initialized (terraform init)
#   - Credentials set via environment variables:
#       export TF_VAR_wiz_client_id="your-client-id"
#       export TF_VAR_wiz_client_secret="your-client-secret"
#
# Usage:
#   ./scripts/import.sh [workspace]
#
# Examples:
#   ./scripts/import.sh prod     # Import into 'prod' workspace
#   ./scripts/import.sh          # Import into 'prod' workspace (default)
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROD_DIR="${SCRIPT_DIR}/../environments/prod"
WORKSPACE="${1:-prod}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check prerequisites
check_prerequisites() {
    if [[ -z "${TF_VAR_wiz_client_id:-}" ]] || [[ -z "${TF_VAR_wiz_client_secret:-}" ]]; then
        log_error "Wiz credentials not set. Please export:"
        echo "  export TF_VAR_wiz_client_id=\"your-client-id\""
        echo "  export TF_VAR_wiz_client_secret=\"your-client-secret\""
        exit 1
    fi

    if ! command -v terraform &> /dev/null; then
        log_error "Terraform is not installed or not in PATH"
        exit 1
    fi
}

# Import a resource if it doesn't already exist in state
import_resource() {
    local resource_address="$1"
    local resource_id="$2"
    local description="$3"

    if terraform -chdir="${PROD_DIR}" state show "${resource_address}" &> /dev/null; then
        log_warn "${description} already in state, skipping"
    else
        log_info "Importing ${description}..."
        terraform -chdir="${PROD_DIR}" import "${resource_address}" "${resource_id}"
        log_info "Successfully imported ${description}"
    fi
}

main() {
    log_info "Starting Wiz Terraform import..."
    echo

    check_prerequisites

    # Ensure Terraform is initialized
    if [[ ! -d "${PROD_DIR}/.terraform" ]]; then
        log_info "Initializing Terraform..."
        terraform -chdir="${PROD_DIR}" init
    fi

    # Select or create workspace
    log_info "Using workspace: ${WORKSPACE}"
    if ! terraform -chdir="${PROD_DIR}" workspace select "${WORKSPACE}" 2>/dev/null; then
        log_info "Creating workspace: ${WORKSPACE}"
        terraform -chdir="${PROD_DIR}" workspace new "${WORKSPACE}"
    fi

    echo
    log_info "Importing resources into Terraform state (workspace: ${WORKSPACE})..."
    echo

    # ==========================================================================
    # SSO Resources (geico-sso.tf)
    # ==========================================================================

    # SAML Identity Provider - GEICO Azure AD
    import_resource \
        "wiz_saml_idp.geico" \
        "GEICO" \
        "SAML IdP (GEICO)"

    # SAML Group Mappings - GEICO AAD groups
    import_resource \
        "wiz_saml_group_mapping.geico_group_mappings" \
        "GEICO" \
        "SAML Group Mappings (GEICO)"

    # ==========================================================================
    # AWS Connector (geico-aws.tf)
    # ==========================================================================

    # AWS Connector - GEICO AWS Organizations
    # Find the connector ID in Wiz Console > Settings > Connectors > [connector] > URL
    import_resource \
        "wiz_aws_connector.geico" \
        "GEICO AWS" \
        "AWS Connector (GEICO)"

    # ==========================================================================
    # GCP Connector (geico-gcp.tf)
    # ==========================================================================

    # GCP Connector - GEICO GCP Organization
    # Find the connector ID in Wiz Console > Settings > Connectors > [connector] > URL
    import_resource \
        "wiz_gcp_connector.geico" \
        "GEICO GCP" \
        "GCP Connector (GEICO)"

    # ==========================================================================
    # Integrations (geico-integrations.tf)
    # ==========================================================================

    # Slack Integration
    # Find the integration ID in Wiz Console > Settings > Integrations > [integration] > URL
    import_resource \
        "wiz_integration.slack" \
        "GEICO Slack" \
        "Slack Integration"

    # Azure DevOps Integration
    import_resource \
        "wiz_integration.ado" \
        "GEICO Azure DevOps" \
        "Azure DevOps Integration"

    # ==========================================================================
    # Automation Rules (geico-automations.tf)
    # ==========================================================================

    # Slack Notification for Critical Issues
    # Find the rule ID in Wiz Console > Response > Automation Rules > [rule] > URL
    # TODO: Get rule ID from Wiz Console
    import_resource \
        "wiz_automation_rule.slack_critical_issues" \
        "RULE_ID" \
        "Automation: Slack Critical Issues"

    # ==========================================================================
    # Add new resources here as they are added to Terraform
    # ==========================================================================
    # Example:
    # import_resource \
    #     "wiz_some_resource.name" \
    #     "resource-id" \
    #     "Description of resource"

    echo
    log_info "Import complete! Running terraform plan to verify..."
    echo

    terraform -chdir="${PROD_DIR}" plan
}

main "$@"

