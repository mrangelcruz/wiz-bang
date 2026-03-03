terraform {
  required_providers {
    null = {
      source = "hashicorp/null"
    }
    aws = {
      source = "hashicorp/aws"
    }
    random = {
      source = "hashicorp/random"
    }
    time = {
      source = "hashicorp/time"
    }
    local = {
      source = "hashicorp/local"
    }
  }

  backend "s3" {
    bucket               = "geico-cloudsec-tfstate-dv"
    key                  = "wiz-dev/terraform.tfstate"
    region               = "us-east-1"
    use_lockfile         = true
    encrypt              = true
    workspace_key_prefix = "wiz-dev"
    assume_role = {
      role_arn = "arn:aws:iam::938436319834:role/geico-cloudsec-tfstate-dv-access"
    }
  }
}



provider "null" {
  # Used for testing state management without creating real resources
}


