terraform {
  required_version = ">= 1.5.0"

  required_providers {
    wiz = {
      source = "tf.app.wiz.io/wizsec/wiz"
    }
  }

  backend "s3" {
    bucket  = "geico-cloudsec-tfstate"
    key     = "wiz-projects/PD/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}
