# Null resource for testing state changes without creating actual infrastructure
resource "null_resource" "pipeline_test" {
  triggers = {
    # Change this timestamp to force a state update during testing
    timestamp   = "2026-01-23T00:00:00Z"
    environment = "dev"
    purpose     = "pipeline-testing"
  }
}

# Random values that generate state but don't create infrastructure
resource "random_string" "test_suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "random_uuid" "test_id" {
  # This creates a UUID and stores it in state
}

# Time-based resource for testing
resource "time_static" "deployment_time" {
  # Captures the time when this resource was created
}

# Local file for testing
resource "local_file" "test_config" {
  filename = "${path.module}/test-output.json"
  content = jsonencode({
    deployment_id   = random_uuid.test_id.result
    deployment_time = time_static.deployment_time.rfc3339
    environment     = "dev"
    test_suffix     = random_string.test_suffix.result
  })
}

# Local values for testing
locals {
  test_config = {
    environment = "dev"
    project     = "wiz-terraform"
    purpose     = "pipeline-testing"
    unique_id   = random_string.test_suffix.result
  }
}

# Output values to verify the pipeline is working
output "test_environment" {
  description = "Confirms the dev environment is working"
  value = {
    environment     = local.test_config.environment
    timestamp       = null_resource.pipeline_test.triggers.timestamp
    state_key       = "wiz-dev/terraform.tfstate"
    deployment_id   = random_uuid.test_id.result
    deployment_time = time_static.deployment_time.rfc3339
  }
}

output "test_resources_created" {
  description = "Summary of test resources created"
  value = {
    random_suffix  = random_string.test_suffix.result
    uuid_generated = random_uuid.test_id.result
    file_created   = local_file.test_config.filename
  }
}

