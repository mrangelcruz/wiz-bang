terraform {
  required_version = ">= 1.5.0"

  required_providers {
    wiz = {
      source = "tf.app.wiz.io/wizsec/wiz"
    }
  }

  backend "s3" {
    bucket               = "geico-cloudsec-tfstate"
    key                  = "wiz/wiz-project-PD.tfstate"
    region               = "us-east-1"
    use_lockfile         = true
    encrypt              = true
    workspace_key_prefix = "wiz"
    assume_role = {
      role_arn = "arn:aws:iam::018139544949:role/geico-cloudsec-tfstate-access"
    }
  }
}
