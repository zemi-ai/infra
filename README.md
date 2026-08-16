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

## Object keys (`gs://zemi-prod-datasets`)

`orgId` is a minted tenant id (Firebase custom claim), not a Firebase uid.

```
customers/{orgId}/projects/{projectId}/raw/{domain}/{relativePath}
customers/{orgId}/projects/{projectId}/processed/{domain}/{product}
customers/{orgId}/projects/{projectId}/uploads/{sessionId}/manifest.json
customers/{orgId}/models/{modelId}/          # later: unified model across projects
```

`domain` is the pipeline name: `geophysics`, `geochemistry`, `geology`, `remote_sensing` (portal `remote-sensing` maps to `remote_sensing`).

## Layout

| File | Purpose |
| --- | --- |
| `versions.tf` | Terraform + Google provider pins |
| `backend.tf` | GCS state (`gs://zemi-prod-tfstate`) |
| `providers.tf` | Google provider |
| `variables.tf` | `project_id`, `region`, bucket/CORS |
| `apis.tf` | Project APIs |
| `datasets.tf` | Landing bucket, portal SA, IAM |
