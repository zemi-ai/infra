resource "google_artifact_registry_repository" "data_pipelines" {
  location      = var.region
  repository_id = var.data_pipelines_repository_id
  description   = "GDAL images for TMI→RTP Cloud Run Jobs (data-pipelines)."
  format        = "DOCKER"
  project       = var.project_id

  depends_on = [google_project_service.apis]
}
