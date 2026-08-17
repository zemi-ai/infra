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

variable "extra_signing_members" {
  type        = list(string)
  description = "Additional IAM members (serviceAccount:...) that may administer dataset objects. Use for the App Hosting runtime SA once it exists."
  default     = []
}
