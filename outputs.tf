output "project_id" {
  description = "Pinned GCP project."
  value       = var.project_id
}

output "region" {
  description = "Pinned default region."
  value       = var.region
}

output "datasets_bucket_name" {
  description = "Landing bucket name."
  value       = google_storage_bucket.datasets.name
}

output "datasets_bucket_url" {
  description = "gs:// URL of the landing bucket."
  value       = google_storage_bucket.datasets.url
}

output "portal_service_account_email" {
  description = "SA the portal should use to mint V4 signed URLs."
  value       = google_service_account.portal.email
}
