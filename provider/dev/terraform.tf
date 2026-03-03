terraform {
  required_providers {
    wiz-azure = {
      source = "local/geico/wiz-azure"
    }
  }
}

provider "wiz-azure" {
  client_id     = var.wiz_client_id
  client_secret = var.wiz_client_secret
  api_url       = var.wiz_api_url
}
