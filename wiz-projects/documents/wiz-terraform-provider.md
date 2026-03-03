# Wiz Terraform Provider

The Wiz Terraform Provider enables you to manage and configure resources within your Wiz environment using Terraform. This provider facilitates resource management automation, allowing you to define infrastructure as code and seamlessly integrate it into your existing Terraform workflows.

Documentation regarding the Data Sources and Resources supported by the Wiz Provider can be found in the navigation to the left.

Popular use cases include managing:

- Custom policies: Controls, Cloud Configuration Rules, and Ignore Rules
- Wiz Projects and user management
- Integrations and automations

Follow the configuration steps to get started or explore the available modules.

Release Notes
The Wiz Terraform Release Notes include a short change log for each released Terraform version. All versions contain general bug fixes and performance improvements which are not explicitly mentioned.

See all available Wiz Terraform Provider releases ↗.

Before you begin
The prerequisites are:

Access to Wiz as a role with W(rite) permissions on the Settings > Service Accounts page. Global roles can create service accounts in all Projects in Wiz; Project-scoped roles can do so only for their Projects. Learn about role-based access control.
Terraform 0.14+ CLI installed locally
One of the following supported architectures:
Darwin amd64
Darwin arm64
Linux amd64
Linux arm64
Windows amd64
Basic knowledge of the Terraform language
Configuration steps
Step 1: Create a Wiz service account

Step 2: Configure Wiz Terraform Provider

Create a Wiz service account
Go to the Settings > Access Management > Service Accounts page in Wiz.
At the top right, click Add Service Account to create a service account of type Custom Integration (GraphQL API).
Assign the necessary permissions based on the data source or resource you want to manage. See the permissions for data sources and resources. For example, to use the wiz_tunnel_server data resource, add the read:connectors permission to the service account.
We recommend creating a service account for each resource and not one common service account for several resources. Only create a service account for multiple resources if they will be used in the same Terraform configuration file.

Configure Wiz Terraform provider
Log in to the environment where Terraform is already installed locally as an Admin user.
Create a new root directory.
In the new root directory, create a versions.tf file and copy the following code:
If you're automatically updating to the latest version of the Wiz Terraform provider, be aware that new versions may introduce breaking changes. While Wiz rarely introduces breaking changes, it can happen. For more information on versioning and best practices, refer to our versioning documentation.

versions.tf
terraform {
  required_providers {
    wiz = {
      source = "tf.app.wiz.io/wizsec/wiz"
    }
  }
}

In the new root directory, create another file named providers.tf and copy the following providers.tf code. For fedramp tenants, copy the fedramp tenant providers.tf code. See the environment property for the list of available Wiz environments.
Select code 👉
providers.tf
fedramp tenant providers.tf
Enter the Wiz service account Client ID and Client Secret you created before in one of the following ways:
Avoid hard-coding credentials into your Terraform configuration files where possible to prevent credential leaks.

(Recommended) Use environment variables
(Not recommended) Hard-code your service account credentials
Example Usage
Terraform
terraform {
  required_providers {
    wiz = {
      source = "tf.app.wiz.io/wizsec/wiz"
    }
  }
}

provider "wiz" {
  client_id = "your client id"
  secret = "you secret"
}

# FedRAMP environment:
provider "wiz" {
  environment = "fedramp"
}

Schema
Required
client_id (String) The service account Client ID for the Wiz portal. This can also be configured using the environment variable WIZ_CLIENT_ID.
secret (String, Sensitive) The service account Secret to connect to the Wiz portal. This can also be configured using the environment variable WIZ_CLIENT_SECRET.
Optional
disable_entity_validations (Boolean) Whether to disable validations for referential Wiz ID inputs. Turning off validations lets you skip checks on Wiz IDs, potentially allowing the insertion of non-existent IDs, which could lead to errors. Alternatively, you can disable the validations by setting the environment variable WIZ_DISABLE_ENTITY_VALIDATIONS.
environment (String) The type of Wiz environment. Defaults to prod. Can be set with the environment variable WIZ_ENVIRONMENT. Possible values: gov, prod, fedramp.
Permissions for data sources and resources
See the permissions for data sources and resources.

Permissions for data sources

Terraform Data Source	Required permission(s)
wiz_cloud_accounts	- read:cloud_accounts
wiz_cloud_configuration_rules	- read:cloud_configuration
wiz_cloud_organizations	- read:cloud_accounts
wiz_container_registries	- read:registries
wiz_controls	- read:controls
wiz_graphql_query	- Dependant on the query being run
wiz_host_configuration_rules	- read:host_configuration
wiz_host_configuration_target_platforms	- any
wiz_image_integrity_validators	- read:image_integrity_validators_settings
wiz_integrations	- read:integrations
wiz_kubernetes_clusters	- read:kubernetes_clusters
wiz_kubernetes_namespaces	- read:resources
wiz_projects	- read:projects
- read:users
wiz_response_actions_catalog	- read:response_action_catalog_items
wiz_repositories	- read:resources
wiz_resource_groups	- read:resources
wiz_saml_idps	- admin:identity_providers
wiz_security_frameworks	- read:security_frameworks
- read:controls
- read:cloud_configuration
- read:host_configuration
wiz_threat_detection_rule	- read:cloud_events_cloud
- read:cloud_event_rules
wiz_tunnel_server	- read:connectors
wiz_users	- read:users
Permissions for resources

Terraform Resource	Required permission(s)
wiz_action_template	- create:action_templates
- read:action_templates
- delete:action_templates
wiz_automation_rule	- create:automation_rules
- read:automation_rules
- update:automation_rules
- delete:automation_rules
- admin:run_response_action
wiz_aws_connector	- create:connectors
- read:connectors
- update:connectors
- delete:connectors
wiz_cicd_scan_policy	- create:scan_policies
- read:scan_policies
- update:scan_policies
- delete:scan_policies
wiz_cloud_configuration_rule	- create:cloud_configuration
- read:cloud_configuration
- update:cloud_configuration
- delete:cloud_configuration
wiz_custom_control
wiz_control	- create:controls
- read:controls
- update:controls
- delete:controls
wiz_custom_rego_package	- create:policy_packages
- read:policy_packages
- update:policy_packages
wiz_data_classification_rule	- create:data_classifiers
- read:data_classifiers
- update:data_classifiers
- delete:data_classifiers
wiz_gcp_connector	- create:connectors
- read:connectors
- update:connectors
- delete:connectors
wiz_github_connector	- create:connectors
- read:connectors
- update:connectors
- delete:connectors
wiz_gitlab_connector	- create:connectors
- read:connectors
- update:connectors
- delete:connectors
wiz_host_configuration_rule	- read:host_configuration
- update:host_configuration
- create:host_configuration
- delete:host_configuration
wiz_ignore_rule	- create:ignore_rules
- read:ignore_rules
- update:ignore_rules
- delete:ignore_rules
The following permissions are required to ensure the successful validation of Policy IDs (i.e., Cloud Configuration Rules, Host Configuration Rules, Vulnerabilities, and Threat Detection Rules):
- read:cloud_configuration
- read:host_configuration
- read:cloud_event_rules
- read:vulnerabilities
- read:data_classifiers
wiz_image_integrity_validator	- read:image_integrity_validators_settings
- update:image_integrity_validators_settings
- write:image_integrity_validators_settings
wiz_integration	- read:integrations
- write:integrations
The following permissions are required to create new integration service accounts:
- read:service_accounts
- write:service_accounts
- Any permission that the integration requires
wiz_kubernetes_connector	- create:connectors
- read:connectors
- update:connectors
- delete:connectors
wiz_project	- admin:projects
- read:projects
- read:users
wiz_remediation_and_response_deployment_v2	- update:remediation_and_response_deployments
- delete:remediation_and_response_deployments
- read:remediation_and_response_deployments
- create:remediation_and_response_deployments
- read:remediation_and_response_connectors
- "read:outposts"
wiz_response_action_catalog_item	- create:response_action_catalog_items
- read:response_action_catalog_items
- update:response_action_catalog_items
- delete:response_action_catalog_items
wiz_report	- create:reports
- read:reports
- update:reports
- delete:reports
wiz_runtime_response_policy	- create:runtime_response_policies
- read:runtime_response_policies
- update:runtime_response_policies
- delete:runtime_response_policies
- read:cloud_events_sensor
wiz_resource_tagging_rule	- create:resource_tagging_rules
- read:resource_tagging_rules
- update:resource_tagging_rules
- delete:resource_tagging_rules
wiz_saved_graph_query	- create:saved_graph_queries
- read:saved_graph_queries
- update:saved_graph_queries
- delete:saved_graph_queries
wiz_saml_idp	- admin:identity_providers
wiz_saml_group_mapping	- admin:identity_providers
wiz_saml_lens_mapping	- admin:identity_providers
wiz_scanner_custom_detection_custom_ip_ranges	- update:scanner_settings
- read:scanner_settings
- write:scanner_settings
wiz_scanner_exclusions	- update:scanner_settings
- read:scanner_settings
- write:scanner_settings
wiz_scanner_nonos_disk_scan	- update:scanner_settings
- read:scanner_settings
- write:scanner_settings
wiz_security_framework	- create:security_frameworks
- read:security_frameworks
- update:security_frameworks
- delete:security_frameworks
- read:controls
- read:host_configuration
- read:cloud_configuration
wiz_service_account	- create:service_accounts
- read:service_accounts
- update:service_accounts
- delete:service_accounts
wiz_threat_detection_rule	- read:security_frameworks
- read:cloud_events_cloud
- read:cloud_event_rules
- update:cloud_event_rules
- create:cloud_event_rules
- delete:cloud_event_rules
- read:cloud_events_sensor
- read:security_scans
wiz_user	- admin:users
- read:users
wiz_user_role	- admin:user_roles
- read:any
Import resources
You can import the following resources from Wiz to Terraform:


Terraform Resource	Can Import from Wiz
wiz_action_template	✅
wiz_automation_rule	✅
wiz_aws_connector	✅
wiz_cicd_scan_policy	✅
wiz_cloud_configuration_rule	✅
wiz_custom_control
wiz_control	✅
wiz_custom_rego_package	✅
wiz_data_classification_rule	✅
wiz_file_upload	✅
wiz_gcp_connector	✅
wiz_github_connector	✅
wiz_gitlab_connector	✅
wiz_host_configuration_rule	✅
wiz_ignore_rule	✅
wiz_image_integrity_validator	✅
wiz_integration	✅
wiz_kubernetes_connector	✅
wiz_project	✅
wiz_remediation_and_response_deployment_v2	✅
wiz_response_action_catalog_item	✅
wiz_resource_tagging_rule	✅
wiz_report	✅
wiz_runtime_response_policy	✅
wiz_saved_graph_query	✅
wiz_saml_idp	✅
wiz_scanner_custom_detection_custom_ip_ranges	✅
wiz_scanner_exclusions	✅
wiz_scanner_nonos_disk_scan	✅
wiz_saml_group_mapping	✅
wiz_saml_lens_mapping	✅
wiz_security_framework	✅
wiz_service_account	✅
wiz_threat_detection_rule	✅
wiz_user	✅
wiz_user_role	✅
