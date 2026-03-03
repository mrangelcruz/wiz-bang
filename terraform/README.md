# Wiz Terraform Configuration

Infrastructure as Code for managing Wiz platform configuration.

## Architecture Overview

![WIZ Terraform Topology](documents/wiz-tf-topology.png)

*The diagram above shows a high-level overview of the Terraform-managed Wiz platform configuration*

## Prerequisites

- [Terraform](https://www.terraform.io/downloads) >= 1.0
- AWS credentials with access to assume the Terraform state role
- Wiz service account credentials with appropriate permissions
- Access to the Wiz tenant

## Directory Structure

```
terraform/
├── environments/
│   ├── DV/                       # Development environment
│   │   ├── main.tf               # Root configuration  
│   │   ├── providers.tf          # Provider setup
│   │   ├── terraform.tfvars      # Non-sensitive variable values
│   │   └── variables.tf          # Variable definitions
│   ├── UT/                       # User Testing environment
│   │   └── [same structure as DV]
│   └── PD/                       # Production environment
│       ├── geico-automations.tf  # Automation rules
│       ├── geico-aws.tf          # AWS Organizations connector
│       ├── geico-gcp.tf          # GCP Organization connector
│       ├── geico-integrations.tf # Slack & ADO integrations
│       ├── geico-sso.tf          # SAML IdP & group mappings
│       ├── main.tf               # Root configuration
│       ├── providers.tf          # Provider setup
│       ├── terraform.tfvars      # Non-sensitive variable values
│       └── variables.tf          # Variable definitions
└── scripts/
    └── import.sh                 # Initial state import script
```

## Deployment Options

### Deploy via GitHub Actions Workflow

Use the automated workflow located in `.github/workflows/deploy-wiz-tf.yml`:

1. Navigate to **Actions** → **WIZ-terraform-deployment** workflow in GitHub
2. Click **"Run workflow"** and provide:
   - **Action**: Choose `plan` or `apply`
   - **Environment**: Choose `DV`, `UT`, or `PD` 
   - **Import existing**: Check for first-time setup to import existing WIZ resources
   - **Confirm**: Type `apply` (required for apply operations only)

**Workflow Actions:**
- `plan`: Validates configuration and shows deployment plan
- `apply`: Executes the deployment plan (requires confirmation)

**Environment Configuration:** 
- Sensitive variables are loaded from GitHub environment secrets
- Environment-specific variables are automatically loaded from `terraform.tfvars` files
- AWS credentials and state access are handled automatically

### Deploy via CLI (Alternative)

For local development and testing:

### 1. Configure Credentials

Source the credentials file from the repository root:

```bash
source .env.wiz
```

The `.env.wiz` file should contain all sensitive variables:

```bash
# Wiz API credentials (required)
export TF_VAR_wiz_client_id="your-wiz-client-id"
export TF_VAR_wiz_client_secret="your-wiz-client-secret"

# Integration credentials (required for integrations)
export TF_VAR_slack_bot_token="xoxb-your-slack-bot-token"
```

> **Note:** `.env.wiz` is gitignored and must never be committed. Each developer must create their own copy with valid credentials.

### 2. Initialize Terraform

```bash
# Choose your environment directory
cd terraform/environments/DV    # For development
cd terraform/environments/UT    # For user testing  
cd terraform/environments/PD    # For production

terraform init
```

### 3. Import Existing Resources (First Run Only)

If the Wiz resources already exist in the console, you must import them into Terraform state before managing them:

```bash
# Run the import script from the terraform directory
./scripts/import.sh
```

Or import manually:

```bash
terraform import wiz_saml_idp.geico GEICO
terraform import wiz_saml_group_mapping.geico_group_mappings GEICO
```

### 4. Plan & Apply

```bash
# Preview changes
terraform plan

# Apply changes
terraform apply
```

## Remote State Configuration

Terraform state is stored in S3 with environment-specific state files. The backend is configured in each environment's `providers.tf`:

**State File Structure:**
- **DV**: `wiz-dv/terraform.tfstate`
- **UT**: `wiz-ut/terraform.tfstate` 
- **PD**: `wiz-pd/terraform.tfstate`

> **Note:** Each environment uses separate state files for isolation. State locking prevents concurrent modifications.

## Resources Managed

| Resource | File | Description |
|----------|------|-------------|
| `wiz_saml_idp.geico` | `geico-sso.tf` | Azure AD SAML Identity Provider |
| `wiz_saml_group_mapping.geico_group_mappings` | `geico-sso.tf` | AAD group to Wiz role mappings |
| `wiz_aws_connector.geico` | `geico-aws.tf` | AWS Organizations connector (all accounts) |
| `wiz_gcp_connector.geico` | `geico-gcp.tf` | GCP Organization connector (all projects) |
| `wiz_integration.slack` | `geico-integrations.tf` | Slack Bot integration |
| `wiz_integration.ado` | `geico-integrations.tf` | Azure DevOps webhook integration |
| `wiz_automation_rule.slack_critical_issues` | `geico-automations.tf` | Slack alert for critical issues |

## Adding New Resources

When adding new Wiz resources:

1. Add the resource configuration to the appropriate `.tf` file
2. If the resource already exists in Wiz, add an import command to `scripts/import.sh`
3. Run the import before applying changes
4. Verify with `terraform plan`

