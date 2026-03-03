terraform {
  required_providers {
    wiz = {
      source = "tf.app.wiz.io/wizsec/wiz"
    }
  }

  backend "s3" {
    bucket               = "geico-cloudsec-tfstate"
    key                  = "wiz/terraform.tfstate"
    region               = "us-east-1"
    use_lockfile         = true
    encrypt              = true
    workspace_key_prefix = "wiz"
    assume_role = {
      role_arn = "arn:aws:iam::018139544949:role/geico-cloudsec-tfstate-access"
    }
  }
}

provider "wiz" {
  # Production Wiz tenant configuration.
  #
  # Credentials are provided via Terraform input variables:
  #   wiz_client_id
  #   wiz_client_secret
  #
  # To avoid committing secrets, set them via environment variables:
  #   export TF_VAR_wiz_client_id="xxxxx"
  #   export TF_VAR_wiz_client_secret="yyyyy"
  #
  # This matches Terraform's recommended pattern for sensitive data and keeps
  # secrets out of the configuration and VCS.

  client_id = var.wiz_client_id
  secret    = var.wiz_client_secret
}

