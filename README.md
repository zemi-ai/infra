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

## Regions

Two regions on purpose. Do not collapse them to make `gcloud` flags uniform.

| What | Region | Why |
| --- | --- | --- |
| GCS datasets, tfstate, Artifact Registry, Cloud Run Jobs | `northamerica-northeast1` (Montreal) | Survey rasters stay in Canada. Jobs read/write the bucket in-region. |
| Firebase App Hosting (portal) | `us-east4` | App Hosting has no Canada region. |

**Commands:** `--region=northamerica-northeast1` (or omit and use the Terraform default) for Storage, Artifact Registry, and Cloud Run Jobs. Portal deploys are Firebase App Hosting, not `gcloud run deploy`. Image hostnames include the region: `northamerica-northeast1-docker.pkg.dev/zemi-prod/data-pipelines/…`.

Browser uploads go **directly to Montreal GCS** (signed PUT). App Hosting only mints the URL — that cross-region hop is metadata, not the grid.

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
| `artifact_registry.tf` | Docker repo `data-pipelines` (TMI→RTP image) |

Image build/push is Docker or Cloud Build in **data-pipelines**, not Terraform. After apply:

```bash
# from data-pipelines
gcloud auth configure-docker northamerica-northeast1-docker.pkg.dev
docker build -t northamerica-northeast1-docker.pkg.dev/zemi-prod/data-pipelines/tmi-rtp:$(git rev-parse --short HEAD) .
docker push northamerica-northeast1-docker.pkg.dev/zemi-prod/data-pipelines/tmi-rtp:$(git rev-parse --short HEAD)
```
