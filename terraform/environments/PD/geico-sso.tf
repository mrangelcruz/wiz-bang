# Wiz SSO configuration (SAML IdP + group mappings).
#
# This file contains:
# - wiz_saml_idp for configuring the GEICO SAML SSO IdP
# - wiz_saml_group_mapping for mapping AAD groups to Wiz roles

resource "wiz_saml_idp" "geico" {
  name       = "GEICO"
  issuer_url = "https://sts.windows.net/7389d8c0-3607-465c-a69f-7d4426502912/"
  login_url  = "https://login.microsoftonline.com/7389d8c0-3607-465c-a69f-7d4426502912/saml2"
  logout_url = "https://login.microsoftonline.com/7389d8c0-3607-465c-a69f-7d4426502912/saml2"

  use_provider_managed_roles   = true
  allow_manual_role_override   = false
  merge_groups_mapping_by_role = false

  certificate = <<-EOT
    -----BEGIN CERTIFICATE-----
    MIIC8DCCAdigAwIBAgIQagFQd14FD6tLefTj6RM/2zANBgkqhkiG9w0BAQsFADA0
    MTIwMAYDVQQDEylNaWNyb3NvZnQgQXp1cmUgRmVkZXJhdGVkIFNTTyBDZXJ0aWZp
    Y2F0ZTAeFw0yNTEwMTQxODA4NDdaFw0yODEwMTQxODA4NDdaMDQxMjAwBgNVBAMT
    KU1pY3Jvc29mdCBBenVyZSBGZWRlcmF0ZWQgU1NPIENlcnRpZmljYXRlMIIBIjAN
    BgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAwrnIcl7xnrNr42TTwkJr0zr5S/nC
    Omg5VdUEPAGBwlJMfHA53Ad22wnAErAmFfnwe/MJc/cz/5jH7SMktYh8452KYHmi
    NXj73YHILPry0cKLc8Ylxu3rikNxFPejIVWG6bqtaOv0jAOOsV43MwFGFguUFAcX
    ufKO3aXMLQaGxDNbhbk8RURCicKDrkVHxtKYKd+xe5ZFojV+Rj76KG/VCa0ZtPx0
    URV2w/T2LO9X0HFp7R5kM+5Lj+2Fn+2C4yNMpyJSBeycYWvBbaw5kAhy18E62Kio
    VOazBV+fqe5PKAddR1MMsYXdOySf1cNv0p/2s3IwXvF2WcV7R4Jy0ASkWQIDAQAB
    MA0GCSqGSIb3DQEBCwUAA4IBAQBLkZF2QQEnR614dfNoV1W8IenN/J+5Nv4DpXXF
    GQyrPjQWDRVMUpHr7DCRrjxSW3xZFTnkYumaedv2pE/CphjXh52VQRn4uKUwgI9r
    mHFMIGXbvf+sH5/0/jQKJm1dbBNIvI+tyXxbgphk4GMHG0hEk+Wm47/lwxcpuTbq
    23YERiYfATLrw+acq+aGDWBY2MuEOK3S4umFlLzkmGKDKe8wMV0x25ZxffT7xJ5E
    VyQc7PkajiagNsquU/XZlApm61wJ1sT/sHSVZLxHnNVtWrS9znGUw0+tMzYX1jTq
    N70LcSnZNH/6f4pGnxH6LMIqZGe+dOOaiYqWmmD81tXoVmtp
    -----END CERTIFICATE-----
  EOT
}

resource "wiz_saml_group_mapping" "geico_group_mappings" {
  saml_idp_id = wiz_saml_idp.geico.id

  # AAD-ASG-WIZ-PD-USER -> Global Reader (all projects)
  group_mapping {
    provider_group_id = "AAD-ASG-WIZ-PD-USER"
    role              = "GLOBAL_READER"
    description       = "Global Reader"
  }

  # AAD-ASG-WIZ-PD-ADMIN -> Global Admin (all projects)
  group_mapping {
    provider_group_id = "AAD-ASG-WIZ-PD-ADMIN"
    role              = "GLOBAL_ADMIN"
    description       = "Global Admin"
  }

  # AAD-ASG-WIZ_AWS-PD-USER -> Project Reader (AWS)
  group_mapping {
    provider_group_id = "AAD-ASG-WIZ_AWS-PD-USER"
    role              = "PROJECT_READER"
    projects          = ["GEICO AWS"]
    description       = "AWS Project Reader"
  }
}

