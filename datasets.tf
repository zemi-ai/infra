resource "google_storage_bucket" "datasets" {
  name     = var.datasets_bucket_name
  project  = var.project_id
  location = var.region

  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  cors {
    origin          = var.datasets_cors_origins
    method          = ["GET", "HEAD", "PUT", "OPTIONS"]
    response_header = ["Content-Type", "Content-Length", "x-goog-resumable"]
    max_age_seconds = 3600
  }

  depends_on = [google_project_service.apis]

  lifecycle {
    prevent_destroy = true
  }
}

locals {
  apphosting_compute_member = "serviceAccount:firebase-app-hosting-compute@${var.project_id}.iam.gserviceaccount.com"
}

# Portal signs V4 URLs as this SA (local next dev). App Hosting signs as
# firebase-app-hosting-compute@, which gets objectAdmin below.
resource "google_service_account" "portal" {
  account_id   = "portal"
  display_name = "Zemi portal (signed GCS uploads)"
  project      = var.project_id

  depends_on = [google_project_service.apis]
}

resource "google_storage_bucket_iam_member" "portal_object_admin" {
  bucket = google_storage_bucket.datasets.name
  role   = "roles/storage.objectAdmin"
  member = google_service_account.portal.member
}

resource "google_service_account_iam_member" "portal_sign_blobs" {
  service_account_id = google_service_account.portal.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = google_service_account.portal.member
}

resource "google_storage_bucket_iam_member" "apphosting_compute_object_admin" {
  bucket = google_storage_bucket.datasets.name
  role   = "roles/storage.objectAdmin"
  member = local.apphosting_compute_member
}

resource "google_service_account_iam_member" "apphosting_compute_sign_blobs" {
  service_account_id = "projects/${var.project_id}/serviceAccounts/firebase-app-hosting-compute@${var.project_id}.iam.gserviceaccount.com"
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = local.apphosting_compute_member
}

resource "google_storage_bucket_iam_member" "extra_object_admin" {
  for_each = toset(var.extra_signing_members)

  bucket = google_storage_bucket.datasets.name
  role   = "roles/storage.objectAdmin"
  member = each.value
}
