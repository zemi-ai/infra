resource "google_project_service" "apis" {
  for_each = toset([
    "iam.googleapis.com",
    "storage.googleapis.com",
    "artifactregistry.googleapis.com",
    "run.googleapis.com",
  ])

  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}
