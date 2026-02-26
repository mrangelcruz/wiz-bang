output "project_id" {
  description = "Project ID (null if creation fails)"
  value       = try(wiz_project.this.id, null)
}


