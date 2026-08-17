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

output "data_pipelines_repository" {
  description = "Artifact Registry Docker repo id."
  value       = google_artifact_registry_repository.data_pipelines.repository_id
}

output "data_pipelines_image_base" {
  description = "Prefix for data-pipelines images (append /tmi-rtp:<tag>)."
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.data_pipelines.repository_id}"
}
