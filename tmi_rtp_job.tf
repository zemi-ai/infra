data "google_project" "current" {
  project_id = var.project_id
}

resource "google_service_account" "tmi_rtp_job" {
  account_id   = "tmi-rtp-job"
  display_name = "TMI→RTP Cloud Run Job"
  project      = var.project_id

  depends_on = [google_project_service.apis]
}

# Demo: whole-bucket objectAdmin. Prefix conditions (raw read / processed write) later.
resource "google_storage_bucket_iam_member" "tmi_rtp_job_object_admin" {
  bucket = google_storage_bucket.datasets.name
  role   = "roles/storage.objectAdmin"
  member = google_service_account.tmi_rtp_job.member
}

resource "google_artifact_registry_repository_iam_member" "cloud_run_pull" {
  project    = var.project_id
  location   = var.region
  repository = google_artifact_registry_repository.data_pipelines.repository_id
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:service-${data.google_project.current.number}@serverless-robot-prod.iam.gserviceaccount.com"
}

resource "google_cloud_run_v2_job" "tmi_rtp" {
  name                = var.tmi_rtp_job_name
  location            = var.region
  project             = var.project_id
  deletion_protection = false

  template {
    template {
      service_account       = google_service_account.tmi_rtp_job.email
      timeout               = var.tmi_rtp_timeout
      max_retries           = 0
      execution_environment = "EXECUTION_ENVIRONMENT_GEN2"

      containers {
        image   = var.tmi_rtp_image
        command = ["zemi", "job", "tmi-rtp"]

        # Per-execution INPUT_GS / OUTPUT_PREFIX_GS / SURVEY_* / INPUT_CRS
        # via `gcloud run jobs execute --update-env-vars`. Do not bake them here.
        env {
          name  = "WORK_DIR"
          value = "/work/zemi-tmi-rtp"
        }

        resources {
          limits = {
            cpu    = var.tmi_rtp_cpu
            memory = var.tmi_rtp_memory
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
          # Provider enum is MEMORY or "" (disk). "DISK" is rejected on google 6.x.
          medium     = ""
          size_limit = var.tmi_rtp_scratch_disk
        }
      }
    }
  }

  depends_on = [
    google_project_service.apis,
    google_artifact_registry_repository.data_pipelines,
    google_artifact_registry_repository_iam_member.cloud_run_pull,
    google_storage_bucket_iam_member.tmi_rtp_job_object_admin,
  ]

  lifecycle {
    ignore_changes = [launch_stage]
  }
}

locals {
  tmi_rtp_invokers = toset([
    local.apphosting_compute_member,
    google_service_account.portal.member,
  ])
}

resource "google_cloud_run_v2_job_iam_member" "portal_execute_tmi_rtp" {
  for_each = local.tmi_rtp_invokers

  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_job.tmi_rtp.name
  role     = "roles/run.jobsExecutorWithOverrides"
  member   = each.value
}

resource "google_service_account_iam_member" "portal_act_as_tmi_rtp_job" {
  for_each = local.tmi_rtp_invokers

  service_account_id = google_service_account.tmi_rtp_job.name
  role               = "roles/iam.serviceAccountUser"
  member             = each.value
}
