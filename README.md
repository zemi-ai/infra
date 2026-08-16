# zemi-ai/infra

Terraform for GCP project **`zemi-prod`**. Portal and `data-pipelines` stay application repos; cloud resources are added here.

Public repo. State is private (GCS, not git).

## Prerequisites

- Terraform `>= 1.7`
- Application Default Credentials: `gcloud auth application-default login`
- Access to `zemi-prod`

## One-time: state bucket

Create this **once** in the console or with `gcloud`. Do not manage it in this root (chicken-and-egg with the backend).

```bash
gcloud storage buckets create gs://zemi-prod-tfstate \
  --project=zemi-prod \
  --location=northamerica-northeast1 \
  --uniform-bucket-level-access

gcloud storage buckets update gs://zemi-prod-tfstate --versioning
# Confirm the bucket is not public (no allUsers / allAuthenticatedUsers).
```

## Usage

```bash
terraform init
terraform plan
terraform apply   # only after reviewing the plan; do not apply unattended
```

Pinned defaults: `project_id = zemi-prod`, `region = northamerica-northeast1`.

## What belongs here

| In Terraform | Console / wizard |
| --- | --- |
| APIs (`google_project_service`) | GCP project + billing (exists) |
| Dataset bucket, CORS, IAM | Firebase Auth users |
| Artifact Registry repo | App Hosting ↔ GitHub |
| Cloud Run Job + job SA | Wix DNS for `portal.zemi.ca` |
| App Hosting SA `run.jobs.run` | |

Do **not** put datasets, models, or client names in this repo.

## Layout

| File | Purpose |
| --- | --- |
| `versions.tf` | Terraform + Google provider pins |
| `backend.tf` | GCS state (`gs://zemi-prod-tfstate`) |
| `providers.tf` | Google provider |
| `variables.tf` | `project_id`, `region` |
| `main.tf` | Resources (empty until ZEM-22) |
