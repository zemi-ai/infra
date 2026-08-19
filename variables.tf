variable "project_id" {
  type        = string
  description = "GCP project for all resources in this root."
  default     = "zemi-prod"
}

variable "region" {
  type        = string
  description = "Default region. Datasets bucket, Artifact Registry, and Cloud Run Job must use this. App Hosting is us-east4 (not available in Canada)."
  default     = "northamerica-northeast1"
}

variable "datasets_bucket_name" {
  type        = string
  description = "Landing bucket for portal uploads and pipeline products."
  default     = "zemi-prod-datasets"
}

variable "datasets_cors_origins" {
  type        = list(string)
  description = "Browser origins allowed to PUT/GET objects via signed URLs."
  default = [
    "http://localhost:3000",
    "https://portal.zemi.ca",
  ]
}

variable "data_pipelines_repository_id" {
  type        = string
  description = "Artifact Registry Docker repo for data-pipelines images."
  default     = "data-pipelines"
}

variable "tmi_rtp_job_name" {
  type        = string
  description = "Cloud Run Job name for TMI→RTP."
  default     = "tmi-rtp"
}

variable "tmi_rtp_image" {
  type        = string
  description = "TMI→RTP image, pinned by digest (not a floating tag). Update when data-pipelines pushes a new linux/amd64 image."
  default     = "northamerica-northeast1-docker.pkg.dev/zemi-prod/data-pipelines/tmi-rtp@sha256:12ca1208608f2dd74fe3b84b5c296131bc16282ab62578abbb4a02cf4e292d9d"
}

variable "tmi_rtp_cpu" {
  type        = string
  description = "Cloud Run Job CPU. Allowed: 1, 2, 4, 6, 8."
  default     = "2"
}

variable "tmi_rtp_memory" {
  type        = string
  description = "Cloud Run Job memory."
  default     = "8Gi"
}

variable "tmi_rtp_scratch_disk" {
  type        = string
  description = "emptyDir size for WORK_DIR (disk, not RAM). Provider uses medium \"\" for disk."
  default     = "16Gi"
}

variable "tmi_rtp_timeout" {
  type        = string
  description = "Per-attempt task timeout. Demo grids should finish in under a minute; raise if a real survey hits the deadline."
  default     = "60s"
}

variable "extra_signing_members" {
  type        = list(string)
  description = "Additional IAM members with objectUser on datasets raw/ and uploads/ prefixes and objectViewer on processed/ (same scope as the portal)."
  default     = []
}
