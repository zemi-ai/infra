variable "project_id" {
  type        = string
  description = "GCP project for all resources in this root."
  default     = "zemi-prod"
}

variable "region" {
  type        = string
  description = "Default region. Datasets bucket, Artifact Registry, and Cloud Run Job must use this."
  default     = "northamerica-northeast1"
}
