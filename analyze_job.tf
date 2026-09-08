resource "google_service_account" "analyze_job" {
  account_id   = "analyze-job"
  display_name = "Analyze Cloud Run Job"
  project      = var.project_id

  depends_on = [google_project_service.apis]
}

# Demo: whole-bucket objectAdmin. Prefix conditions (raw+processed read /
# processed write) later.
resource "google_storage_bucket_iam_member" "analyze_job_object_admin" {
  bucket = google_storage_bucket.datasets.name
  role   = "roles/storage.objectAdmin"
  member = google_service_account.analyze_job.member
}

resource "google_cloud_run_v2_job" "analyze" {
  name                = var.analyze_job_name
  location            = var.region
  project             = var.project_id
  deletion_protection = false

  template {
    template {
      service_account       = google_service_account.analyze_job.email
      timeout               = var.analyze_timeout
      max_retries           = 0
      execution_environment = "EXECUTION_ENVIRONMENT_GEN2"

      containers {
        # Same data-pipelines image as TMI→RTP (geo + gcp + ml extras).
        image   = var.analyze_image
        command = ["zemi", "job", "analyze"]

        # Per-execution OCCURRENCES_GS / ANALYZE_MANIFEST_GS / OUTPUT_PREFIX_GS
        # / ORG_ID via `gcloud run jobs execute --update-env-vars`.
        env {
          name  = "WORK_DIR"
          value = "/work/zemi-analyze"
        }

        resources {
          limits = {
            cpu    = var.analyze_cpu
            memory = var.analyze_memory
          }
        }

        volume_mounts {
          name       = "scratch"
          mount_path = "/work"
        }
      }

      volumes {
        name = "scratch"
        empty_dir {
          medium     = ""
          size_limit = var.analyze_scratch_disk
        }
      }
    }
  }

  depends_on = [
    google_project_service.apis,
    google_artifact_registry_repository.data_pipelines,
    google_artifact_registry_repository_iam_member.cloud_run_pull,
    google_storage_bucket_iam_member.analyze_job_object_admin,
  ]

  lifecycle {
    ignore_changes = [launch_stage]
  }
}

locals {
  analyze_invokers = toset([
    local.apphosting_compute_member,
    google_service_account.portal.member,
  ])
}

resource "google_cloud_run_v2_job_iam_member" "portal_execute_analyze" {
  for_each = local.analyze_invokers

  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_job.analyze.name
  role     = "roles/run.jobsExecutorWithOverrides"
  member   = each.value
}

# jobsExecutorWithOverrides cannot read execution status.
resource "google_cloud_run_v2_job_iam_member" "portal_view_analyze" {
  for_each = local.analyze_invokers

  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_job.analyze.name
  role     = "roles/run.viewer"
  member   = each.value
}

resource "google_service_account_iam_member" "portal_act_as_analyze_job" {
  for_each = local.analyze_invokers

  service_account_id = google_service_account.analyze_job.name
  role               = "roles/iam.serviceAccountUser"
  member             = each.value
}
