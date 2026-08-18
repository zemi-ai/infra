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
  # GCS IAM conditions allow startsWith/endsWith/extract, not matches().
  # extract() picks the path segment after .../projects/{id}/ (raw vs uploads).
  portal_object_cel         = "resource.name.startsWith('projects/_/buckets/${google_storage_bucket.datasets.name}/objects/customers/') && (resource.name.extract('/objects/customers/{org}/projects/{proj}/{kind}/') == 'raw' || resource.name.extract('/objects/customers/{org}/projects/{proj}/{kind}/') == 'uploads')"
}

# Local next dev IAM-signs as this SA. App Hosting signs as
# firebase-app-hosting-compute@. Both are scoped to raw/ and uploads/.
resource "google_service_account" "portal" {
  account_id   = "portal"
  display_name = "Zemi portal (signed GCS uploads)"
  project      = var.project_id

  depends_on = [google_project_service.apis]
}

resource "google_storage_bucket_iam_member" "portal_objects" {
  bucket = google_storage_bucket.datasets.name
  role   = "roles/storage.objectUser"
  member = google_service_account.portal.member

  condition {
    title       = "raw-and-uploads"
    description = "customers/*/projects/*/raw and customers/*/projects/*/uploads only"
    expression  = local.portal_object_cel
  }
}

resource "google_service_account_iam_member" "portal_sign_blobs" {
  service_account_id = google_service_account.portal.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = google_service_account.portal.member
}

resource "google_storage_bucket_iam_member" "apphosting_compute_objects" {
  bucket = google_storage_bucket.datasets.name
  role   = "roles/storage.objectUser"
  member = local.apphosting_compute_member

  condition {
    title       = "raw-and-uploads"
    description = "customers/*/projects/*/raw and customers/*/projects/*/uploads only"
    expression  = local.portal_object_cel
  }
}

resource "google_service_account_iam_member" "apphosting_compute_sign_blobs" {
  service_account_id = "projects/${var.project_id}/serviceAccounts/firebase-app-hosting-compute@${var.project_id}.iam.gserviceaccount.com"
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = local.apphosting_compute_member
}

resource "google_storage_bucket_iam_member" "extra_objects" {
  for_each = toset(var.extra_signing_members)

  bucket = google_storage_bucket.datasets.name
  role   = "roles/storage.objectUser"
  member = each.value

  condition {
    title       = "raw-and-uploads"
    description = "customers/*/projects/*/raw and customers/*/projects/*/uploads only"
    expression  = local.portal_object_cel
  }
}

moved {
  from = google_storage_bucket_iam_member.portal_object_admin
  to   = google_storage_bucket_iam_member.portal_objects
}

moved {
  from = google_storage_bucket_iam_member.extra_object_admin
  to   = google_storage_bucket_iam_member.extra_objects
}
