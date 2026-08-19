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
| Cloud Run Job + job SA + App Hosting execute IAM | Wix DNS for `portal.zemi.ca` |

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
| `variables.tf` | `project_id`, `region`, bucket/CORS, job image digest |
| `apis.tf` | Project APIs |
| `datasets.tf` | Landing bucket, portal SA, IAM |
| `artifact_registry.tf` | Docker repo `data-pipelines` (TMI→RTP image) |
| `tmi_rtp_job.tf` | Cloud Run Job `tmi-rtp` + job SA |

Image build/push is Docker or Cloud Build in **data-pipelines**, not Terraform. After apply, pin the new digest in `tmi_rtp_image` and re-apply.

```bash
# from data-pipelines (linux/amd64 — Cloud Run will not run a Mac ARM image)
gcloud auth configure-docker northamerica-northeast1-docker.pkg.dev
docker build --platform linux/amd64 \
  -t northamerica-northeast1-docker.pkg.dev/zemi-prod/data-pipelines/tmi-rtp:$(git rev-parse --short HEAD) .
docker push northamerica-northeast1-docker.pkg.dev/zemi-prod/data-pipelines/tmi-rtp:$(git rev-parse --short HEAD)
```

## TMI→RTP job (execute)

The Job resource has no `INPUT_GS` baked in. Pass survey params per execution. `OUTPUT_PREFIX_GS` is the domain prefix (`…/processed/geophysics`), not a filename.

```bash
gcloud run jobs execute tmi-rtp \
  --region=northamerica-northeast1 \
  --project=zemi-prod \
  --update-env-vars=ORG_ID=ORG,INPUT_GS=gs://zemi-prod-datasets/customers/ORG/projects/PROJECT/raw/geophysics/survey.grd,OUTPUT_PREFIX_GS=gs://zemi-prod-datasets/customers/ORG/projects/PROJECT/processed/geophysics,SURVEY_YEAR=2022,SURVEY_ELEVATION_M=1690,INPUT_CRS=EPSG:32614
```

Required env: `ORG_ID`, `INPUT_GS`, `OUTPUT_PREFIX_GS`, `SURVEY_YEAR`, `SURVEY_ELEVATION_M`. Both URIs must be under `customers/{ORG_ID}/`. `INPUT_CRS` is required for Geosoft `.grd`. Outputs: `{stem}_rtp.tif`, `_anomaly.tif`, `_rtp_color.tif`, `_rtp_color.png`.
