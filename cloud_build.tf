# GitHub host connection is console-once (OAuth / GitHub App). Terraform links
# the data-pipelines repo and creates the main-only trigger.

locals {
  cloudbuild_service_agent = "serviceAccount:service-${data.google_project.current.number}@gcp-sa-cloudbuild.iam.gserviceaccount.com"
  tmi_rtp_image_prefix     = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.data_pipelines.repository_id}/${var.tmi_rtp_image_name}"
}

resource "google_service_account" "data_pipelines_build" {
  account_id   = "data-pipelines-build"
  display_name = "Cloud Build data-pipelines images"
  project      = var.project_id

  depends_on = [google_project_service.apis]
}

resource "google_artifact_registry_repository_iam_member" "cloudbuild_push" {
  project    = var.project_id
  location   = var.region
  repository = google_artifact_registry_repository.data_pipelines.repository_id
  role       = "roles/artifactregistry.writer"
  member     = google_service_account.data_pipelines_build.member
}

resource "google_project_iam_member" "data_pipelines_build_logs" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = google_service_account.data_pipelines_build.member
}

# gcloud builds submit stages source here. GitHub triggers clone via the
# Cloud Build agent; this still covers manual submits and GCS log fallback.
resource "google_storage_bucket_iam_member" "data_pipelines_build_source" {
  bucket = "${var.project_id}_cloudbuild"
  role   = "roles/storage.objectAdmin"
  member = google_service_account.data_pipelines_build.member
}

resource "google_service_account_iam_member" "cloudbuild_act_as_build" {
  service_account_id = google_service_account.data_pipelines_build.name
  role               = "roles/iam.serviceAccountUser"
  member             = local.cloudbuild_service_agent
}

resource "google_cloudbuildv2_repository" "data_pipelines" {
  project           = var.project_id
  location          = var.region
  name              = var.data_pipelines_github_repo
  parent_connection = var.cloudbuild_github_connection
  remote_uri        = "https://github.com/${var.data_pipelines_github_owner}/${var.data_pipelines_github_repo}.git"

  depends_on = [google_project_service.apis]
}

resource "google_cloudbuild_trigger" "data_pipelines_main" {
  project     = var.project_id
  location    = var.region
  name        = "data-pipelines-tmi-rtp"
  description = "Build tmi-rtp and push to Artifact Registry on main. Does not update the Cloud Run Job."
  filename    = "cloudbuild.yaml"

  repository_event_config {
    repository = google_cloudbuildv2_repository.data_pipelines.id
    push {
      branch = "^main$"
    }
  }

  substitutions = {
    _REGION     = var.region
    _REPOSITORY = var.data_pipelines_repository_id
    _IMAGE_NAME = var.tmi_rtp_image_name
  }

  service_account = google_service_account.data_pipelines_build.id

  depends_on = [
    google_project_service.apis,
    google_artifact_registry_repository_iam_member.cloudbuild_push,
    google_project_iam_member.data_pipelines_build_logs,
    google_storage_bucket_iam_member.data_pipelines_build_source,
    google_service_account_iam_member.cloudbuild_act_as_build,
  ]
}
