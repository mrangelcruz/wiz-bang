# wiz_project

The resource wiz_project lets you manage Wiz Projects. This resource is available from version >= 1.3.189.

Use Projects to group your cloud resources according to their users and/or purposes.

The following schemas are deprecated:

- kubernetes_cluster_links
- kubernetes_cluster_links.resource_names

Use the following schemas instead:

- kubernetes_cluster_set_links
- kubernetes_cluster_tags_links
- kubernetes_cluster_universal_links

## Before you begin

The prerequisites are:

- Familiar with Wiz Projects
- Configured Wiz Terraform provider and a Wiz service account with these permissions:
- - admin:projects
- - read:projects
- - read:users

Example Usage
Terraform

```
# Example of GDPR Prod project
resource "wiz_project" "production-GDPR-project" {
  name               = "production-GDPR-project"
  project_owners     = ["36833f58-5037-5d11-8db4-eb1d3dced6c9"]
  security_champions = ["36833f58-5037-5d11-8db4-eb1d3dced6c9"]
  parent_project_id  = ""
  description        = "This Projects holds our production resources for our GDPR-certified app"

  is_folder = false
  archived  = false
  risk_profile {
    is_actively_developed = "YES"
    has_authentication    = "NO"
    has_exposed_api       = "YES"
    is_internet_facing    = "YES"
    is_customer_facing    = "YES"
    stores_data           = "YES"
    business_impact       = "HBI"
    is_regulated          = "YES"
    sensitive_data_types  = ["CLASSIFIED"]
    regulatory_standards  = ["GDPR"]
  }
  cloud_account_links {
    cloud_account_id = "7b777b7b-bbb7-77b7-bb7b-77777b77bb77"
    environment      = "PRODUCTION"
    shared = true
    add_shared_object_to_project = true
  }
  cloud_account_links {
    cloud_account_id = "cc55cccc-cc55-5c55-5555-cc5555c5c55c"
    environment      = "PRODUCTION"
  }

  tags {
    key   = "environment"
    value = "production"
  }
  category = "Environment"
}

# Example of folder project.  Note that if this folder has sub projects a delete will not work unless all sub projects are deleted first.
# Also if archive_on_delete is set to true on a sub project, the parent project much have archive_on_delete set to true.
resource "wiz_project" "folder_project_prod" {
  name        = "folder_project_prod"
  description = "This Projects holds our production projects"
  is_folder   = true
  archive_on_delete = true
  risk_profile {
    is_actively_developed = "YES"
    has_authentication    = "YES"
    has_exposed_api       = "YES"
    is_internet_facing    = "YES"
    is_customer_facing    = "YES"
    stores_data           = "YES"
    business_impact       = "HBI"
    is_regulated          = "YES"
  }
}

# Example of AWS project
resource "wiz_project" "aws_project_prod" {
  name              = "aws_project_prod"
  description       = "This Projects holds our production AWS cloud accounts"
  is_folder         = false
  archive_on_delete = true
  parent_project_id = wiz_project.folder_project_prod.id
  risk_profile {
    is_actively_developed = "YES"
    has_authentication    = "YES"
    has_exposed_api       = "YES"
    is_internet_facing    = "YES"
    is_customer_facing    = "YES"
    stores_data           = "YES"
    business_impact       = "HBI"
    is_regulated          = "YES"
  }
  cloud_organization_links {
    cloud_organization = "cc55cccc-cc55-5c55-5555-cc5555c5c55c"
  }
}

# Example of GCP project
resource "wiz_project" "gcp_project_prod" {
  name              = "gcp_project_prod"
  description       = "This Projects holds our production GCP projects"
  is_folder         = false
  parent_project_id = wiz_project.folder_project_prod.id
  risk_profile {
    is_actively_developed = "YES"
    has_authentication    = "YES"
    has_exposed_api       = "YES"
    is_internet_facing    = "YES"
    is_customer_facing    = "YES"
    stores_data           = "YES"
    business_impact       = "HBI"
    is_regulated          = "YES"
  }
  cloud_organization_links {
    cloud_organization = "7b777b7b-bbb7-77b7-bb7b-77777b77bb77"
  }
}

# Example of Kubernetes project
resource "wiz_project" "kubernetes_project_prod1" {
  name              = "kubernetes_project_prod"
  description       = "This Projects holds Kubernetes production clusters"
  is_folder         = false
  parent_project_id = ""
  risk_profile {
    is_actively_developed = "YES"
    has_authentication    = "YES"
    has_exposed_api       = "YES"
    is_internet_facing    = "YES"
    is_customer_facing    = "YES"
    stores_data           = "YES"
    business_impact       = "HBI"
    is_regulated          = "YES"
  }
  kubernetes_cluster_links {
    kubernetes_cluster = "7b777b7b-bbb7-77b7-bb7b-77777b77bb77"
  }
  kubernetes_cluster_links {
    kubernetes_cluster = "cc55cccc-cc55-5c55-5555-cc5555c5c55c"
  }
}

# Example of Kubernetes project
resource "wiz_project" "kubernetes_project_prod2" {
  name              = "kubernetes_project_prod"
  description       = "This Projects holds Kubernetes production clusters"
  is_folder         = false
  parent_project_id = ""
  risk_profile {
    is_actively_developed = "YES"
    has_authentication    = "YES"
    has_exposed_api       = "YES"
    is_internet_facing    = "YES"
    is_customer_facing    = "YES"
    stores_data           = "YES"
    business_impact       = "HBI"
    is_regulated          = "YES"
  }
  kubernetes_cluster_universal_links{
    cluster_filters{
      namespace_tags{
        key = "prod"
        value = "prod"
      }
    }
  }
}

# Example of Kubernetes project
resource "wiz_project" "kubernetes_project_prod3" {
  name              = "kubernetes_project_prod"
  description       = "This Projects holds Kubernetes production clusters"
  is_folder         = false
  parent_project_id = ""
  risk_profile {
    is_actively_developed = "YES"
    has_authentication    = "YES"
    has_exposed_api       = "YES"
    is_internet_facing    = "YES"
    is_customer_facing    = "YES"
    stores_data           = "YES"
    business_impact       = "HBI"
    is_regulated          = "YES"
  }
  kubernetes_cluster_tags_links {
    kubernetes_cluster_tags {
      key   = "prod"
      value = "prod"
    }
  }
}

# Example of repositories project
resource "wiz_project" "repositories_project_prod" {
  name              = "repositories_project_prod"
  description       = "This Projects holds production repositories"
  is_folder         = false
  archive_on_delete = true
  parent_project_id = ""
  risk_profile {
    is_actively_developed = "YES"
    has_authentication    = "YES"
    has_exposed_api       = "YES"
    is_internet_facing    = "YES"
    is_customer_facing    = "NO"
    stores_data           = "YES"
    business_impact       = "HBI"
    is_regulated          = "YES"
  }
  repository_links {
    repository = "7b777b7b-bbb7-77b7-bb7b-77777b77bb77"
  }
  repository_links {
    repository = "cc55cccc-cc55-5c55-5555-cc5555c5c55c"
  }
}

# Example of container registries project
resource "wiz_project" "container_registries_project_prod" {
  name              = "container_registries_project_prod"
  description       = "This Projects holds production container registries"
  is_folder         = false
  parent_project_id = ""
  risk_profile {
    is_actively_developed = "YES"
    has_authentication    = "YES"
    has_exposed_api       = "YES"
    is_internet_facing    = "YES"
    is_customer_facing    = "NO"
    stores_data           = "YES"
    business_impact       = "HBI"
    is_regulated          = "YES"
  }
  container_registry_links {
    container_registry_id = "7b777b7b-bbb7-77b7-bb7b-77777b77bb77"
  }
  container_registry_links {
    container_registry_id = "cc55cccc-cc55-5c55-5555-cc5555c5c55c"
  }
}

# Example of version control organization project
resource "wiz_project" "version_control_org_project_prod" {
  name              = "version_control_org_project_prod"
  description       = "This Projects holds production version control org"
  is_folder         = false
  parent_project_id = ""
  risk_profile {
    is_actively_developed = "YES"
    has_authentication    = "YES"
    has_exposed_api       = "YES"
    is_internet_facing    = "YES"
    is_customer_facing    = "NO"
    stores_data           = "YES"
    business_impact       = "HBI"
    is_regulated          = "YES"
  }
  version_control_organization_links {
    cloud_organization = "7b777b7b-bbb7-77b7-bb7b-77777b77bb77"
    topics             = ["prod", "stage"]
  }
}

# Example of Cloud Account Tags project.
resource "wiz_project" "account_tags" {
  name               = "terraform-account-tags"
  project_owners     = []
  security_champions = []
  description        = "terraform account tags project"
  archived  = false
  cloud_account_tags_links{
    cloud_account_tags{
      key = "environment"
      value = "production"
    }
    resource_tags{
      key = "environment"
      value = "production"
    }
  }
}

# Example of Resource Filter project
resource "wiz_project" "resource_filter_project" {
  name        = "terraform-resource-filter-project"
  project_owners = []
  security_champions = []
  description = "terraform resource filter project"
  is_folder   = false
  archived    = false
  resource_filter_links {
    resource_names {
      contains = ["prod", "security"]
    }
  }
}

# Example leveraging a data source and dynamic blocks for Cloud Account association
data "wiz_cloud_accounts" "prod_names_lookup" {
  search         = ["prod", "production"]
  cloud_provider = ["AWS"]
}

resource "wiz_project" "aws_prod" {
  name               = "terraform AWS cloud acounts - production"
  project_owners     = []
  security_champions = []
  description        = "project that contains AWS production accounts"
  is_folder          = false
  archived           = false
  risk_profile {
    is_actively_developed = "YES"
    has_authentication    = "NO"
    has_exposed_api       = "YES"
    is_internet_facing    = "YES"
    is_customer_facing    = "YES"
    stores_data           = "YES"
    business_impact       = "HBI"
    is_regulated          = "YES"
    sensitive_data_types  = ["CLASSIFIED"]
    regulatory_standards  = ["GDPR"]
  }

  dynamic "cloud_account_links" {
    for_each = data.wiz_cloud_accounts.prod_names_lookup.cloud_accounts
    content {
      cloud_account_id = cloud_account_links.value.id
    }
  }
}

# Example leveraging a data source and dynamic blocks for Cloud Organization association
data "wiz_cloud_organizations" "external_id_lookup" {
  search = ["tenantId/1df56910-a0c4-4966-a78d-06b1ea77a16d/providers/Microsoft.Management/managementGroups/1df56910-a0c4-4966-a78d-06b1ea77a16d"]
}

resource "wiz_project" "parent_folder" {
  name               = "terraform-parent-folder"
  project_owners     = []
  security_champions = []
  parent_project_id  = "b26913a3-e8a0-5a5b-89da-73ff8e0cf6d7"
  description        = "terraform parent project"

  is_folder = true
  archived  = false
}

resource "wiz_project" "terraform_child" {
  name               = "terraform-child"
  project_owners     = []
  security_champions = []
  parent_project_id  = wiz_project.parent_folder.id
  description        = "terraform child project"

  is_folder = false
  archived  = false
  risk_profile {
    is_actively_developed = "YES"
    has_authentication    = "NO"
    has_exposed_api       = "YES"
    is_internet_facing    = "YES"
    is_customer_facing    = "YES"
    stores_data           = "YES"
    business_impact       = "HBI"
    is_regulated          = "YES"
    sensitive_data_types  = ["CLASSIFIED"]
    regulatory_standards  = ["GDPR"]
  }

  dynamic "cloud_organization_links" {
    for_each = data.wiz_cloud_organizations.external_id_lookup.cloud_organizations
    content {
      cloud_organization = cloud_organization_links.value.id
    }
  }
}

```

## Schema

### Required

- name (String) The name of the Project. Must be unique across all current and archived Projects.

### Optional

- archive_on_delete (Boolean) Whether to archive the project on a destroy instead of deleting it. Defaults to false.
- archived (Boolean) Whether the Project is archived/inactive. Defaults to false.
- business_unit (String) The business unit(s) the Project belongs to.
- category (String) The security category IDs to associate with the Project. New Issues created by the Project will be tagged with the selected categories.
- cloud_account_links (Block Set) The cloud account/subscription/project to be associated directly with the Project by the Wiz identifier UUID. Use to organize all the subscription resources, Issues, and findings within this Project. (see below for nested schema)
- cloud_account_tags_links (Block Set) Associate the Project with cloud accounts tags. (see below for nested schema)
- cloud_organization_links (Block Set) The cloud organization to be associated directly with the Project by the Wiz identifier UUID. Use to organize all the subscription resources, Issues, and findings within this Project. (see below for nested schema)
- cloud_organization_tags_links (Block Set) Associate the Project with cloud organizations tags. (see below for nested schema)
- container_registry_links (Block Set) Associate the Project with container registries. (see below for nested schema)
- creation_method (String) This property will always get the value TERRAFORM when modifying projects via Wiz Terraform provider. Trying to give it other values will cause diffs.
- description (String) The Project description.
- identifiers (Set of String) The identifiers for the Project. To reset, explicitly set to an empty list [].
- is_folder (Boolean) Whether the Project is a Folder Project. Defaults to false. Folder Projects can contain other Projects or Folder Projects only; they cannot contain cloud resources. Use Folder Projects to group Projects hierarchically. This value can't be changed after the creation due to Wiz API restrictions.
- is_import_module_usage (Boolean) Internal flag indicating if this resource is being managed by a Terraform module. Defaults to false.
- kubernetes_cluster_links (Block Set) The Kubernetes cluster to be associated directly with the Project by the Wiz identifier UUID. Use to organize all the subscription resources, Issues, and findings within this Project. (see below for nested schema)
- kubernetes_cluster_set_links (Block Set) Associate the Project with Kubernetes cluster sets. (see below for nested schema)
- kubernetes_cluster_tags_links (Block Set) Add a Kubernetes cluster by key/value tags to the Project. (see below for nested schema)
- kubernetes_cluster_universal_links (Block Set) Associate the Project with all the Kubernetes clusters in the tenant. (see below for nested schema)
- parent_project_id (String) The Project's parent Project ID.
- project_owners (Set of String) The Project owner IDs. To reset, explicitly set to an empty list [].
repository_links (Block Set) The repositories to associate with the Project. (see below for nested schema)
- resource_filter_links (Block Set) Associate the Project with resource filters. (see below for nested schema)
- risk_profile (Block Set, Max: 1) Contains properties specifying the risk profile the new Project's resources might pose to your organization. (see below for nested schema)
security_champions (Set of String) The Project security champion IDs . To reset, explicitly set to an empty list [].
- slug (String) Enter a unique slug as an identifier for the Project. Similar to the Project name, the slug must be unique.
- tags (Block Set) Add key/value tags to the Project. Use tags to help organize and identify your Projects. (see below for nested schema)
- version_control_organization_links (Block Set) Associate the Project with version control organizations. (see below for nested schema)

### Read-Only

- id (String) The unique internal identifier for the Project, as defined by Wiz.

### Nested Schema for
- cloud_account_links

#### Required:

- cloud_account_id (String) The Wiz internal identifier for the cloud account/subscription/project.

#### Optional:

- add_shared_object_to_project (Boolean) Indicates whether the shared object should be added to the project. Only relevant when 'shared' is true.
- environment (String) The environment type of the cloud account/subscription/project. Defaults to PRODUCTION. Possible values: PRODUCTION, STAGING, DEVELOPMENT, TESTING, OTHER.
- resource_group_tags (Block Set) Resource Group tags used as a matching rule to link to this project. (see below for nested schema)
- resource_groups (Set of String) Add cloud account/subscription/project resources by group identifiers to the Project. To define resource_groups, shared must be set to true.
- resource_names (Block Set) Add resources by name to the Project. (see below for nested schema)
- resource_tags (Block Set) Add cloud account/subscription/project resources by key/value tags to the Project. To define - resource_tags, shared must be set to true. (see below for nested schema)
- shared (Boolean) Whether the cloud account/subscription/project contains multiple Projects. Defaults to true. Will be marked as ‘shared subscriptions’. Resources within can be filtered using tags. If you set this value to false, any additional filters will be ignored.

### Nested Schema forcloud_account_links.resource_group_tags

#### Required:

- key (String) The resource tag key.
- value (String) The resource tag value.

### Nested Schema for cloud_account_links.resource_names

#### Optional:

- contains (Set of String) List of resource names to match.
- ends_with (Set of String) List of resource names to match.
- equals (Set of String) List of resource names to match.
- starts_with (Set of String) List of resource names to match.

### Nested Schema for cloud_account_links.resource_tags

#### Required:

- key (String) The resource tag key.

#### Optional:

- value (String) The resource tag value.
- value_contains (String) The resource tag value contains filter.

### Nested Schema for
- cloud_account_tags_links

#### Optional:

- add_shared_object_to_project (Boolean) Indicates whether the shared object should be added to the project. Only relevant when 'shared' is true.
- cloud_account_tags (Block Set) The key/value tags for filtering cloud accounts. (see below for nested schema)
- environment (String) The environment type of the cloud account/subscription/project. Defaults to PRODUCTION. Possible values: PRODUCTION, STAGING, DEVELOPMENT, TESTING, OTHER.
- resource_names (Block Set) Add resources by name to the Project. (see below for nested schema)
- resource_tags (Block Set) Add cloud account/subscription/project resources by key/value tags to the Project. To define resource_tags, shared must be set to true. (see below for nested schema)
- shared (Boolean) Whether the cloud account/subscription/project contains multiple Projects. Defaults to true. Will be marked as ‘shared subscriptions’. Resources within can be filtered using tags. If you set this value to false, any additional filters will be ignored.

### Nested Schema for cloud_account_tags_links.cloud_account_tags

#### Required:

- key (String) The resource tag key.

#### Optional:

- value (String) The resource tag value.
- value_contains (String) The resource tag value contains filter.

### Nested Schema for cloud_account_tags_links.resource_names

#### Optional:

- contains (Set of String) List of resource names to match.
- ends_with (Set of String) List of resource names to match.
- equals (Set of String) List of resource names to match.
- starts_with (Set of String) List of resource names to match.
- Nested Schema for
- cloud_account_tags_links.resource_tags

#### Required:

- key (String) The resource tag key.

#### Optional:

- value (String) The resource tag value.
- value_contains (String) The resource tag value contains filter.

### Nested Schema forcloud_organization_links

#### Required:

- cloud_organization (String) The Wiz internal identifier for the cloud organization.

#### Optional:

- add_shared_object_to_project (Boolean) Indicates whether the shared object should be added to the project. Only relevant when 'shared' is true.
- environment (String) The environment type of the cloud organization. Defaults to PRODUCTION. Possible values: PRODUCTION, STAGING, DEVELOPMENT, TESTING, OTHER.
- resource_group_tags (Block Set) Resource Group tags used as a matching rule to link to this project. (see below for nested schema)
- resource_groups (Set of String) Add cloud organization resources by group identifiers to the Project. To define resource_groups, shared must be set to true.
- resource_names (Block Set) Add resources by name to the Project. (see below for nested schema)
- resource_tags (Block Set) Add cloud organization resources by key/value tags to the Project. To define resource_tags, shared must be set to true. (see below for nested schema)
- shared (Boolean) Whether the cloud organization encompasses multiple Projects. Defaults to true. Will be marked as ‘shared subscriptions’. Resources within can be filtered using tags. If you set this value to false, any additional filters will be ignored.

### Nested Schema for cloud_organization_links.resource_group_tags

#### Required:

- key (String) The resource tag key.
- value (String) The resource tag value.

### Nested Schema for cloud_organization_links.resource_names

#### Optional:

- contains (Set of String) List of resource names to match.
- ends_with (Set of String) List of resource names to match.
- equals (Set of String) List of resource names to match.
- starts_with (Set of String) List of resource names to match.

### Nested Schema for cloud_organization_links.resource_tags

#### Required:

- key (String) The resource tag key.

#### Optional:

- value (String) The resource tag value.
- value_contains (String) The resource tag value contains filter.

### Nested Schema for cloud_organization_tags_links

### Optional:

- add_shared_object_to_project (Boolean) Indicates whether the shared object should be added to the project. Only relevant when 'shared' is true.
- cloud_organization_tags (Block Set) The key/value tags for filtering cloud organizations. (see below for nested schema)
- environment (String) The environment type of the cloud organization/project. Defaults to PRODUCTION. Possible values: PRODUCTION, STAGING, DEVELOPMENT, TESTING, OTHER.
- resource_names (Block Set) Add resources by name to the Project. (see below for nested schema)
- resource_tags (Block Set) Add cloud organization/project resources by key/value tags to the Project. To define resource_tags, shared must be set to true. (see below for nested schema)
- shared (Boolean) Whether the cloud organization/project contains multiple Projects. Defaults to true. Will be marked as ‘shared subscriptions’. Resources within can be filtered using tags. If you set this value to false, any additional filters will be ignored.

### Nested Schema for cloud_organization_tags_links.cloud_organization_tags

#### Required:

- key (String) The resource tag key.

#### Optional:

- value (String) The resource tag value.
- value_contains (String) The resource tag value contains filter.

### Nested Schema for cloud_organization_tags_links.resource_names

#### Optional:

- contains (Set of String) List of resource names to match.
- ends_with (Set of String) List of resource names to match.
- equals (Set of String) List of resource names to match.
- starts_with (Set of String) List of resource names to match.

### Nested Schema for cloud_organization_tags_links.resource_tags

#### Required:

- key (String) The resource tag key.

#### Optional:

- value (String) The resource tag value.
- value_contains (String) The resource tag value contains filter.

### Nested Schema for container_registry_links

#### Required:

- container_registry_id (String) The container registry ID to associate with the Project.

#### Optional:

- environment (String) The environment type of the container registry. Defaults to PRODUCTION. Possible values: PRODUCTION, STAGING, DEVELOPMENT, TESTING, OTHER.
- resource_names (Block Set) Add resources by name to the Project. (see below for nested schema)

### Nested Schema for container_registry_links.resource_names

### Optional:

- contains (Set of String) List of resource names to match.
- ends_with (Set of String) List of resource names to match.
- equals (Set of String) List of resource names to match.
- starts_with (Set of String) List of resource names to match.

### Nested Schema for kubernetes_cluster_links

#### Required:

- kubernetes_cluster (String) The Wiz internal identifier for the Kubernetes cluster.

#### Optional:

- add_shared_object_to_project (Boolean) Indicates whether the shared object should be added to the project. Only relevant when 'shared' is true.
- environment (String) The environment type of the Kubernetes cluster. Defaults to PRODUCTION. Possible values: PRODUCTION, STAGING, DEVELOPMENT, TESTING, OTHER.
- namespaces (Set of String) Add Kubernetes namespaces to the Project. To define namespaces, shared must be set to true
- resource_names (Block Set) Add resources by name to the Project. (see below for nested schema)
- shared (Boolean) Whether the Kubernetes cluster encompasses multiple Projects. Defaults to true. Marks as 'shared', allowing resource filtering using namespaces. If namespaces are specified, this must be set to true. If you set this value to false, any additional filters will be ignored.

#### Nested Schema for kubernetes_cluster_links.resource_names
#### Optional:

- contains (Set of String) List of resource names to match.
- ends_with (Set of String) List of resource names to match.
- equals (Set of String) List of resource names to match.
- starts_with (Set of String) List of resource names to match.

### Nested Schema for kubernetes_cluster_set_links
#### Optional:

- add_shared_object_to_project (Boolean) Indicates whether the shared object should be added to the project. Only relevant when 'shared' is true.
- cluster_filters (Block Set, Max: 1) Filters for the Kubernetes Cluster. (see below for nested schema)
- environment (String) The environment type of the Kubernetes cluster. Defaults to PRODUCTION. Possible values: PRODUCTION, STAGING, DEVELOPMENT, TESTING, OTHER.
- kubernetes_clusters (Set of String) The Kubernetes cluster IDs.

### Nested Schema for kubernetes_cluster_set_links.cluster_filters
#### Optional:

- namespace_names (Set of String) The Kubernetes namespace names to link.
- namespace_tags (Block Set) Add namespaces by key/value tags to the Project. (see below for nested schema)
- resource_tags (Block Set) Add resources by key/value tags to the Project. (see below for nested schema)

### Nested Schema for kubernetes_cluster_set_links.cluster_filters.namespace_tags
#### Required:

- key (String) The namespace tag key.
- value (String) The namespace tag value.

### Nested Schema for kubernetes_cluster_set_links.cluster_filters.resource_tags
#### Required:

- key (String) The resource tag key.

#### Optional:

- value (String) The resource tag value.
- value_contains (String) The resource tag value contains filter.

### Nested Schema for kubernetes_cluster_tags_links
#### Optional:

- add_shared_object_to_project (Boolean) Indicates whether the shared object should be added to the project. Only relevant when 'shared' is true.
- cluster_filters (Block Set, Max: 1) Filters for the Kubernetes cluster. (see below for nested schema)
- environment (String) The environment type of the Kubernetes cluster. Defaults to PRODUCTION. Possible values: PRODUCTION, STAGING, DEVELOPMENT, TESTING, OTHER.
- kubernetes_cluster_tags (Block Set) The key/value tags for filtering Kubernetes clusters. (see below for nested schema)

### Nested Schema for kubernetes_cluster_tags_links.cluster_filters
#### Optional:

- namespace_names (Set of String) The kubernetes namespace names to link.
- namespace_tags (Block Set) Provide a key and value pair for filtering namespaces. (see below for nested schema)
- resource_tags (Block Set) Provide a key and value pair for filtering resources. (see below for nested schema)

### Nested Schema for kubernetes_cluster_tags_links.cluster_filters.namespace_tags

#### Required:

- key (String) The namespace tag key.
- value (String) The namespace tag value.

### Nested Schema for kubernetes_cluster_tags_links.cluster_filters.resource_tags
#### Required:

- key (String) The resource tag key.

#### Optional:

- value (String) The resource tag value.
- value_contains (String) The resource tag value contains filter.

### Nested Schema for kubernetes_cluster_tags_links.kubernetes_cluster_tags
#### Required:

- key (String) The resource tag key.
- value (String) The resource tag value.

### Nested Schema for kubernetes_cluster_universal_links

#### Optional:

- add_shared_object_to_project (Boolean) Indicates whether the shared object should be added to the project. Only relevant when 'shared' is true.
- cluster_filters (Block Set, Max: 1) Filters for the Kubernetes cluster. (see below for nested schema)
- environment (String) The environment type of the Kubernetes cluster. Defaults to PRODUCTION. Possible values: PRODUCTION, STAGING, DEVELOPMENT, TESTING, OTHER.

### Nested Schema for kubernetes_cluster_universal_links.cluster_filters
#### Optional:

- namespace_names (Set of String) The Kubernetes namespaces names to link.
- namespace_tags (Block Set) Provide a key and value pair for filtering namespaces. (see below for nested schema)
- resource_tags (Block Set) Provide a key and value pair for filtering resources. (see below for nested schema)

### Nested Schema for kubernetes_cluster_universal_links.cluster_filters.namespace_tags
#### Required:

- key (String) The namespace tag key.
- value (String) The namespace tag value.

### Nested Schema for kubernetes_cluster_universal_links.cluster_filters.resource_tags
#### Required:

- key (String) The resource tag key.

#### Optional:

- value (String) The resource tag value.
- value_contains (String) The resource tag value contains filter.

### Nested Schema for repository_links
#### Required:

- repository (String) The repository to associate with the project

#### Optional:

- resource_names (Block Set) Add repositories by name to the Project. (see below for nested schema)

### Nested Schema for repository_links.resource_names
#### Optional:

- contains (Set of String) List of resource names to match.
- ends_with (Set of String) List of resource names to match.
- equals (Set of String) List of resource names to match.
- starts_with (Set of String) List of resource names to match.

### Nested Schema for resource_filter_links
### Optional:

- environment (String) The environment type of the resource. Defaults to PRODUCTION. Possible values: PRODUCTION, STAGING, DEVELOPMENT, TESTING, OTHER.
- resource_names (Block Set) Add resources by name to the Project. (see below for nested schema)
- resource_tags (Block Set, Deprecated) Add resources by key/value tags to the Project (see below for nested schema)
- resource_tags_v2 (Block Set) Add resources by key/value tags to the Project. (see below for nested schema)

### vNested Schema for resource_filter_links.resource_names
### Optional:

- contains (Set of String) List of resource names to match.
- ends_with (Set of String) List of resource names to match.
- equals (Set of String) List of resource names to match.
- starts_with (Set of String) List of resource names to match.

### Nested Schema for resource_filter_links.resource_tags
#### Required:

- key (String) The resource tag key.

#### Optional:

- value (String) The resource tag value.
- value_contains (String) The resource tag value contains filter.

### Nested Schema for resource_filter_links.resource_tags_v2
#### Optional:

- equals_all (Block Set) Filter by all of the tags (AND logical operator). For each key, specify a single value. (see below for nested schema)
- equals_all_case_insensitive (Block Set) Filter by all of the tags (AND logical operator) case insensitively. For each key, specify a single value. (see below for nested schema)
- equals_any (Block Set) Filter by any of the tags (OR logical operator) (see below for nested schema)
- equals_any_case_insensitive (Block Set) Filter by any of the tags (OR logical operator) case insensitively (see below for nested schema)

### Nested Schema for resource_filter_links.resource_tags_v2.equals_all
#### Required:

- key (String) The resource tag key.

#### Optional:

- value (String) The resource tag value.
- value_contains (String) The resource tag value contains filter.

### Nested Schema for resource_filter_links.resource_tags_v2.equals_all_case_insensitive
#### Required:

- key (String) The resource tag key.

### Optional:

- value (String) The resource tag value.
- value_contains (String) The resource tag value contains filter.

### Nested Schema for resource_filter_links.resource_tags_v2.equals_any
#### Required:

- key (String) The resource tag key.

#### Optional:

- value (String) The resource tag value.
- value_contains (String) The resource tag value contains filter.

### Nested Schema for resource_filter_links.resource_tags_v2.equals_any_case_insensitive
#### Required:

- key (String) The resource tag key.

#### Optional:

- value (String) The resource tag value.
- value_contains (String) The resource tag value contains filter.

### Nested Schema for risk_profile
#### Optional:

- business_impact (String) The business impact: how important are the resources in the Project (Low, Medium, High). Defaults to MBI. Possible values: LBI, MBI, HBI
- has_authentication (String) If the resources in the Project require users to authenticate. Defaults to UNKNOWN. Possible values: YES, NO, UNKNOWN.
- has_exposed_api (String) If the resources in the Project are accessible via an API, e.g. HTTP, REST, GRPC, GraphQL, etc. Defaults to UNKNOWN. Possible values: YES, NO, UNKNOWN.
- is_actively_developed (String) If the Project is under active development. Defaults to UNKNOWN. Possible values: YES, NO, UNKNOWN.
- is_customer_facing (String) If the resources in the Project are customer-facing. Defaults to UNKNOWN. Possible values: YES, NO, UNKNOWN.
- is_internet_facing (String) If the resources in the Project are internet-facing. Defaults to UNKNOWN. Possible values: YES, NO, UNKNOWN.
- is_regulated (String) If resources in this Project are an or subject to a compliance audit. Defaults to UNKNOWN. Possible values: YES, NO, UNKNOWN.
- regulatory_standards (Set of String) The Project's regulartory standards. Possible values: ISO_20000_1_2011, ISO_22301, ISO_27001, ISO_27017, ISO_27018, ISO_27701, ISO_9001, SOC, FEDRAMP, NIST_800_171, NIST_CSF, HIPPA_HITECH, HIPAA_HITECH, HITRUST, PCI_DSS, SEC_17A_4, SEC_REGULATION_SCI, SOX, GDPR.
- sensitive_data_types (Set of String) The sensitive data types in the Project. Possible values: CLASSIFIED, HEALTH, PII, PCI, FINANCIAL, CUSTOMER.
- stores_data (String) If resources in this Project store persistent data, e.g. in databases. Defaults to UNKNOWN. Possible values: YES, NO, UNKNOWN.

### Nested Schema for tags
#### Required:

- key (String) The tag key.

#### Optional:

- value (String) The tag value.

### Nested Schema for version_control_organization_links
#### Required:

- cloud_organization (String) The Wiz internal identifier for the version control organization.

#### Optional:

- add_shared_object_to_project (Boolean) Indicates whether the shared object should be added to the project. Only relevant when 'shared' is true.
- environment (String) The environment type of the version control organization. Defaults to PRODUCTION. Possible values: PRODUCTION, STAGING, DEVELOPMENT, TESTING, OTHER.
- resource_names (Block Set) Add resources by name to the Project. (see below for nested schema)
- shared (Boolean) Whether the version control organization encompasses multiple Projects. Defaults to true. Will be marked as ‘shared subscriptions’. Resources within can be filtered using tags. If you set this value to false, any additional filters will be ignored.
- topics (Set of String) Include repositories with topics that match one of the following values.

### Nested Schema for version_control_organization_links.resource_names
#### Optional:

- contains (Set of String) List of resource names to match.
- ends_with (Set of String) List of resource names to match.
- equals (Set of String) List of resource names to match.
- starts_with (Set of String) List of resource names to match.