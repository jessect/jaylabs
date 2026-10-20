# Lab 003 — Run GCP Locally: Terraform + GCP Emulators

> 🎬 **Video:** coming soon
>
> **Tested with:** Terraform 1.16.6 · Google provider 8.7.0 · fake-gcs-server 1.56.1 · Google Cloud CLI emulators image 589.0.0 (Pub/Sub 0.8.37, Firestore 1.22.0, Spanner 1.5.58, Bigtable) · gcloud 570.0.0 · Docker 29.9.1 · Ubuntu 24.04 (WSL2)

Build a small GCP stack with Terraform **without a GCP project, without a billing account and without
logging in**. There is no LocalStack for GCP that Terraform can talk to, so this lab runs five local
emulators side by side and points the `google` provider at each one with its `*_custom_endpoint`
setting. Terraform really creates the resources, and `gcloud`, `cbt` and `curl` read them back.

## Goal

- Run five emulators with Docker Compose: [fake-gcs-server](https://github.com/fsouza/fake-gcs-server) for Cloud Storage
  and Google's own emulators for Pub/Sub, Firestore, Spanner and Bigtable.
- Point the Terraform `google` provider at them (custom endpoints + a fake access token).
- Create a bucket and an object, Pub/Sub topics with a dead-letter subscription, a Spanner instance and database,
  a Firestore document and a Bigtable table.
- Prove it works with `gcloud`, `cbt` and `curl`, then tear everything down.
- Know exactly which GCP services Terraform **cannot** emulate, and why.

## Architecture

```text
                                  terraform apply
                                        │
     ┌───────────────┬──────────────────┼─────────────────┬──────────────────┐
     ▼               ▼                  ▼                 ▼                  ▼
 :4443 REST      :8085 REST         :8080 REST        :9020 REST         :8086 gRPC
 fake-gcs-server Pub/Sub emulator   Firestore emul.   Spanner emulator   Bigtable emulator
 ┌─────────────┐ ┌───────────────┐  ┌──────────────┐  ┌──────────────┐   ┌───────────────┐
 │ bucket      │ │ orders ─────► │  │ config/      │  │ instance     │   │ table events  │
 │ (versioned) │ │ orders-worker │  │ feature-flags│  │ db orders    │   │ family: order │
 │ app.json    │ │ orders-dlq    │  │ (document)   │  │ table Orders │   │               │
 └─────────────┘ └───────────────┘  └──────────────┘  └──────────────┘   └───────────────┘
   storage_         pubsub_           firestore_         spanner_          BIGTABLE_
   custom_endpoint  custom_endpoint   custom_endpoint    custom_endpoint   EMULATOR_HOST
```

| File | What it does |
|---|---|
| `providers.tf` | `google` provider with a fake `access_token` and four `*_custom_endpoint` settings |
| `variables.tf` | `project_id` (any ID works), `region`, `prefix`, and the map of emulator endpoints |
| `storage.tf` | Versioned GCS bucket + a JSON object (`config/app.json`) |
| `pubsub.tf` | Topic `orders`, dead-letter topic, subscription with `dead_letter_policy` and `retry_policy` |
| `databases.tf` | Spanner instance + database (DDL), Firestore document, Bigtable table |
| `outputs.tf` | Every name `check.sh` needs |
| `docker-compose.yml` | fake-gcs-server + four emulators from one `google-cloud-cli:*-emulators` image |
| `scripts/emulators.env` | `source` it: Bigtable env var for Terraform, and an isolated `gcloud` config pointed at the emulators |
| `scripts/check.sh` | Smoke test of every resource with `gcloud`, `cbt` and `curl` |
| `examples/naive-provider/` | The "just set a project" provider, to show what happens without local endpoints |
| `examples/broken/` | A `google_bigtable_instance` that the emulator cannot create (copy it in to see the error) |
| `terraform.tfvars.example` | Copy to `terraform.tfvars` to change project ID, region or name prefix |
| `Makefile` | Shortcuts: `make up`, `make health`, `make apply`, `make check`, `make destroy`, `make down`, `make naive` |

## Prerequisites

Tested on Ubuntu 24.04 (WSL2) and Ubuntu 22.04.

| Tool | Version tested |
|---|---|
| Docker Engine + Compose plugin | 29.9.1 / v5.6.0 |
| Terraform | 1.16.6 (Google provider 8.7.0) |
| Google Cloud CLI (`gcloud`) | 570.0.0 (no login needed) |
| `cbt` (Bigtable CLI) | `sudo apt-get install google-cloud-cli-cbt`, or `gcloud components install cbt` |
| `curl`, `jq` | any |

The first `make up` downloads two images: `fsouza/fake-gcs-server` (~85 MB on disk) and
`gcr.io/google.com/cloudsdktool/google-cloud-cli:589.0.0-emulators` (~450 MB download, 1.7 GB on disk, shared by four emulators).

## Estimated cost

**$0.** Nothing is created in a real GCP project. Every emulator is free and open source
(fake-gcs-server is BSD-2-Clause, the Google emulators ship with the Cloud CLI). No account, no billing,
no service account key.

## Run it

```bash
make up                         # docker compose up -d + wait for the 5 emulators
source scripts/emulators.env    # BIGTABLE_EMULATOR_HOST + local gcloud config
terraform init
terraform apply -auto-approve   # ~8 s, 9 resources
make check                      # GCS, Pub/Sub, Spanner, Firestore, Bigtable
terraform destroy -auto-approve # ~3 s
make down
```

```text
$ make health
fake-gcs  :4443 ok
pubsub    :8085 ok
firestore :8080 ok
spanner   :9020 ok
bigtable  :8086 ok
```

```text
Apply complete! Resources: 9 added, 0 changed, 0 destroyed.
```

`make check` (abridged):

```text
== Cloud Storage (fake-gcs-server)
NAME                   LOCATION     VERSIONING_ENABLED
jaylabs-lab003-assets  US-CENTRAL1  True
{"database":"orders","env":"local","topic":"jaylabs-lab003-orders"}
== Pub/Sub
ackDeadlineSeconds: 20
deadLetterPolicy:
  deadLetterTopic: projects/jaylabs-local/topics/jaylabs-lab003-orders-dlq
  maxDeliveryAttempts: 5
topic: projects/jaylabs-local/topics/jaylabs-lab003-orders
{"order_id":"order-001"}
== Spanner
NAME                    CONFIG           STATE
jaylabs-lab003-spanner  emulator-config  READY
OrderId    Item      Qty
order-001  keyboard  2
== Firestore
{ "max_items": { "integerValue": "10" }, "new_checkout": { "booleanValue": true } }
== Bigtable
"order-001"
  "order:item"                             @ 2026/10/20-03:56:05.127000
    "keyboard"
```

## How the provider is pointed at the emulators

```hcl
provider "google" {
  project      = var.project_id
  region       = var.region
  access_token = "owner"

  storage_custom_endpoint   = "http://localhost:4443/storage/v1/"
  pubsub_custom_endpoint    = "http://localhost:8085/v1/"
  firestore_custom_endpoint = "http://localhost:8080/v1/"
  spanner_custom_endpoint   = "http://localhost:9020/v1/"
}
```

- **`access_token`** stops the provider from looking for real credentials. The emulators accept any
  token, except Firestore, which only accepts `owner` (see errors below).
- **Custom endpoints** must be full REST base URLs ending with `/`. The provider speaks REST, so the
  Spanner emulator is reached on its REST port `9020`, not the gRPC port `9010`.
- **Bigtable** is the exception: the provider uses the gRPC Bigtable client, which reads
  `BIGTABLE_EMULATOR_HOST=localhost:8086` from the environment.
- **gcloud** gets its own empty config folder (`CLOUDSDK_CONFIG=.gcloud-local`), a token file and
  `CLOUDSDK_API_ENDPOINT_OVERRIDES_*`, so your real `gcloud` login is never touched.

## Real errors you will hit (and the fix)

| When | Error | Fix |
|---|---|---|
| Provider with only `project` + `region` (`make naive`) | `Attempted to load application default credentials since neither credentials nor access_token was set in the provider block. No credentials loaded.` | `access_token` + one `*_custom_endpoint` per service (see `providers.tf`) |
| Any fake token, e.g. `access_token = "fake-token"` | `Error creating Document: googleapi: Error 400: invalid jwt` (Firestore only, every other emulator accepts it) | `access_token = "owner"`: the Firestore emulator's admin token |
| `bigtable_custom_endpoint = "localhost:8086"` | `"bigtable_custom_endpoint" ("localhost:8086") doesn't match regexp ".*/[^/]+/$"` | Remove it and `export BIGTABLE_EMULATOR_HOST=localhost:8086` (in `scripts/emulators.env`) |
| A `google_bigtable_instance` resource | `Error creating instance. rpc error: code = Unimplemented desc = unimplemented feature` | The emulator has no instance API: create only `google_bigtable_table` with any `instance_name` |
| Bucket with `location = "US"`, second `plan` | `~ location = "US-CENTRAL1" -> "US" # forces replacement` on **every** plan | `location = "US-CENTRAL1"` (fake-gcs-server always answers with its `-location` flag) |
| Bucket with `labels`, second `plan` | `Plan: 0 to add, 1 to change` forever: fake-gcs-server drops bucket labels | No labels on the bucket in this lab (real GCS keeps them) |
| `terraform destroy` with the Spanner database default | `Error: cannot destroy instance without setting deletion_protection=false and running terraform apply` | `deletion_protection = false` on `google_spanner_database`, apply, then destroy (lab only) |
| `terraform plan` with an emulator stopped | `Get "http://localhost:8085/v1/projects/jaylabs-local/topics/jaylabs-lab003-orders?alt=json": dial tcp 127.0.0.1:8085: connect: connection refused` | `make up` again |
| Emulators restarted | `# google_pubsub_topic.orders has been deleted` ... `Plan: 9 to add` | Re-apply. Every emulator here keeps its data in memory only |
| Same Firestore document created from a second state | `Error 409: entity already exists: EntityRef[partitionRef=dev~jaylabs-local, path=/config/feature-flags]` | One state per document, or `terraform import` it |

## Why only these services?

The `google` provider talks to almost every GCP API over **REST**. An emulator is only useful to
Terraform if it speaks the same REST API on a URL you can put in a `*_custom_endpoint`.

| Service | Local option | Terraform apply |
|---|---|---|
| Cloud Storage | fake-gcs-server (REST) | ✅ bucket, object |
| Pub/Sub | Google emulator (REST + gRPC) | ✅ topic, subscription, dead-letter policy |
| Spanner | Google emulator (REST on 9020) | ✅ instance (`emulator-config`), database + DDL |
| Firestore | Google emulator (REST) | ✅ documents only (no `google_firestore_database`) |
| Bigtable | Google emulator (gRPC) | ⚠️ tables only, via `BIGTABLE_EMULATOR_HOST` |
| Compute, VPC, IAM, Cloud SQL, GKE, Cloud Run | none | ❌ no local API exists |
| Secret Manager, KMS, Cloud Tasks | [localgcp](https://github.com/slokam-ai/localgcp) (gRPC only) | ❌ `HTTP/1.x transport connection broken: malformed HTTP response` |

## What the emulators do NOT prove

| Emulators prove | Emulators do NOT prove |
|---|---|
| Your HCL is valid and the provider can create, read and destroy these resources | IAM: every request is accepted, any token, any project |
| Resource wiring: subscription → topic, dead-letter topic, database → instance | Locations, regions, quotas, org policies, globally unique bucket names |
| Your app can publish, read rows and objects against the same names | Real latency, real limits (Spanner nodes, Pub/Sub throughput) |
| The plan is stable (no drift) **on the emulator** | Real GCS keeps labels and location; fake-gcs-server does not, so drift differs |
| | Compute Engine, VPC, Cloud SQL, GKE: no emulator, not covered at all |

## Cleanup

```bash
terraform destroy -auto-approve
make down                       # docker compose down + remove .gcloud-local
```
