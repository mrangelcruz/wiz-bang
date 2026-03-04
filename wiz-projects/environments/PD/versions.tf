terraform {
  required_version = ">= 1.5.0"

  required_providers {
    wiz = {
      source = "tf.app.wiz.io/wizsec/wiz"
    }
  }

  backend "azurerm" {
    resource_group_name  = "tfstate-np-rg"
    storage_account_name = "tfstatezscalergznp"
    container_name       = "tfstate"
    key                  = "wiz-project-PD.tfstate"
    use_oidc             = true
  }
}
