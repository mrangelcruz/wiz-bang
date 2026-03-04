# GEICO AWS project (UUID: b044c7e1-bae8-5365-aa29-42a1a193dc1f)

resource "wiz_project" "this" {
  name              = var.project_name
  parent_project_id = "7e546d52-0d84-5fb3-af02-71c7c8a66c1e"

  cloud_organization_links {
    cloud_organization           = "5555e3b6-44da-5a6e-9851-d34f5b8e081e"
    environment                  = "PRODUCTION"
    shared                       = false
    add_shared_object_to_project = false
  }

  risk_profile {
    business_impact       = "MBI"
    has_authentication    = "UNKNOWN"
    has_exposed_api       = "UNKNOWN"
    is_actively_developed = "UNKNOWN"
    is_customer_facing    = "UNKNOWN"
    is_internet_facing    = "UNKNOWN"
    is_regulated          = "UNKNOWN"
    stores_data           = "UNKNOWN"
  }
}
