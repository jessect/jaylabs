# Lab 003 — Test Terraform on GCP with no project and no billing account: `terraform test` + `mock_provider`

> 🎬 **Video:** coming soon
>
> **Tested with:** Terraform 1.16.6 · Google provider 8.7.0 · random 3.9.1 · Ubuntu 24.04 (WSL2)

Write real tests for a small GCP stack (VPC, firewall, GCS, Compute Engine, Cloud SQL, Secret Manager,
IAM) **without a GCP project, without a billing account and without logging in**. Terraform's native
`terraform test` replaces the Google provider with `mock_provider "google"`, so the tests run in
~3 seconds, fully offline, on your laptop.

This lab goes past the basics: a reusable module tested on its own, shared mock files, realistic
`mock_data`, `override_resource` / `override_data` / `override_module`, `override_during = plan`,
and `expect_failures` on validation, preconditions and postconditions.

## Goal

- Run `terraform plan` / `terraform test` with the real provider and watch it fail (no credentials).
- Mock the Google provider and give it **realistic** values (`google_client_config`, `google_compute_zones`, service account email).
- Test `for_each`, conditional resources (`count`), dynamic blocks and per-environment rules.
- Prove that bad input is rejected: variable validation, preconditions, postconditions.
- Test a module directly, then replace it with `override_module` to test only the root.
- Know exactly **what mocks cannot prove**.

## Architecture

```text
                    terraform test   (mock_provider "google": nothing leaves your laptop)
                           │
      ┌────────────────────┼─────────────────────────────────────────────────────────┐
      │ module "network"   │ root                                                    │
      │ ┌────────────────┐ │ ┌──────────────┐ ┌──────────────┐ ┌──────────────────┐  │
      │ │ VPC (custom)   │ │ │ GCS bucket   │ │ Service acct │ │ Secret Manager   │  │
      │ │ subnets ×N     │─┼▶│ Compute VM   │◀│ + 2 IAM roles│ │ db password      │  │
      │ │ (for_each)     │ │ │ private IP   │ │ (for_each)   │ │ (random_password)│  │
      │ │ fw: internal   │ │ └──────────────┘ └──────────────┘ └──────────────────┘  │
      │ │ fw: SSH (IAP)  │ │ ┌──────────────────────────────────────────┐            │
      │ └────────────────┘ │ │ Cloud SQL Postgres 16: prod or opt-in    │            │
      │                    │ │ (count = 0/1, REGIONAL in prod)          │            │
      │                    │ └──────────────────────────────────────────┘            │
      └────────────────────┴─────────────────────────────────────────────────────────┘
        dev: 13 resources · prod: 14 resources · real GCP calls: 0
```

| File | What it does |
|---|---|
| `providers.tf` | `google` (~> 8.0) and `random` (~> 3.6), provider with `project` + `region` only, no credentials |
| `variables.tf` | `project_id`, `region`, `environment`, `machine_type` with `validation` blocks; `subnets` map |
| `main.tf` | `data "google_client_config"`, locals (name, labels, `is_prod`), the `network` module call |
| `modules/network/` | Reusable module: custom VPC, one subnet per map entry, internal + IAP SSH firewall rules, input validation |
| `storage.tf` | GCS bucket: public access blocked, versioning in prod, 30-day delete rule elsewhere (dynamic block) |
| `iam.tf` | Service account (with a **postcondition** on its email) + `for_each` IAM roles |
| `compute.tf` | `data "google_compute_zones"`, `e2-micro` VM, private IP only, two **preconditions** |
| `secrets.tf` | `random_password` stored in a Secret Manager secret |
| `database.tf` | Cloud SQL Postgres 16, only in prod or with `enable_database = true` |
| `outputs.tf` | Bucket, VM, service account, secret and database outputs |
| `tests/mocks/google.tfmock.hcl` | Shared mock values for every test file |
| `tests/plan.tftest.hcl` | Plan-only unit tests: naming, labels, dev vs prod, staging opt-in, `for_each` |
| `tests/validation.tftest.hcl` | `expect_failures`: variables, preconditions, postcondition, `override_data`, `override_resource` |
| `tests/apply.tftest.hcl` | Mocked `apply`: outputs, IAM, real `random_password`, `override_resource`, run-to-run references |
| `tests/network_module.tftest.hcl` | The module tested directly (`module {}` in a run) and replaced with `override_module` |
| `tests/limits.tftest.hcl` | A test that passes with nonsense values: what mocks do NOT prove |
| `examples/mock-steps/` | 7 small test files, one per real error below (`make step STEP=01-empty-mock`) |
| `examples/naive-provider/` | Real provider, no mocks: `plan` and `test` both fail on credentials |
| `Makefile` | `make init`, `make validate`, `make test`, `make test-verbose`, `make step`, `make naive`, … (`make help`) |

## Prerequisites

| Tool | Version tested |
|---|---|
| Terraform | 1.16.6 (needs ≥ 1.11 for `override_during`) |
| Google provider | 8.7.0 (downloaded by `terraform init`) |
| random provider | 3.9.1 |
| make | any |

No GCP account, no `gcloud`, no billing account, no service account key.

## Estimated cost

**$0.** Nothing is ever created. Not even a GCP project exists for this lab.

## Run it

```bash
make init        # terraform init: providers + the local module
make validate    # fmt -check + validate, no credentials needed
make test        # 16 tests, ~3 s
```

```text
tests/apply.tftest.hcl... in progress
  run "dev_apply"... pass
  run "prod_apply"... pass
...
tests/apply.tftest.hcl... pass
tests/limits.tftest.hcl... pass
tests/network_module.tftest.hcl... pass
tests/plan.tftest.hcl... pass
tests/validation.tftest.hcl... pass

Success! 16 passed, 0 failed.
```

`make test-verbose` prints the mocked plan of every run (`Plan: 13 to add` for dev, `14` for prod).

## First, without mocks

```bash
make naive         # terraform plan with the real provider
make naive-test    # terraform test with no mock_provider
```

Both stop at `Error: Attempted to load application default credentials ... No credentials loaded.`
See [`examples/naive-provider`](examples/naive-provider).

## The techniques

### Shared, realistic mocks

Every test file points at the same mock folder:

```hcl
mock_provider "google" {
  source = "./tests/mocks"
}
```

`tests/mocks/google.tfmock.hcl` sets what a real project would return: provider region/project
(`google_client_config`), the zones of `europe-west1` (`google_compute_zones`), a real-looking service
account email and the VM's internal IP. Without them the mock returns random 8-character strings and
empty lists.

### `override_during = plan`

Computed values (like a service account email) are unknown during `plan`. Setting
`override_during = plan` makes the mocked value available at plan time, so plan-only tests can assert
on it. Set **every** computed attribute when you do this (see errors below).

### `override_resource`, `override_data`, `override_module`

| Block | Used in | Why |
|---|---|---|
| `override_data` | `validation.tftest.hcl` | Zones lookup returns `us-central1-a`: the precondition must fail |
| `override_resource` | `validation.tftest.hcl` | Service account in another project: the postcondition must fail |
| `override_resource` | `apply.tftest.hcl` | Give Cloud SQL a real `PROJECT:REGION:INSTANCE` connection name |
| `override_module` | `network_module.tftest.hcl` | Skip the network module, test only how the root uses its outputs |

### `expect_failures`

| Run | Expected failure |
|---|---|
| `project_id = "My_Project"` | `var.project_id` (validation) |
| `environment = "qa"` | `var.environment` (validation) |
| `environment = "prod"` with `e2-micro` | `google_compute_instance.app` (precondition) |
| Zones from another region | `google_compute_instance.app` (precondition) |
| Service account email in another project | `google_service_account.app` (postcondition) |
| `ssh_source_ranges = ["0.0.0.0/0"]` (module run) | `var.ssh_source_ranges` (module validation) |
| `cidr = "10.30.1.0/33"` (module run) | `var.subnets` (module validation) |

## Real errors you will hit (and the fix)

Most of them can be replayed with `make step STEP=<folder>` (folders in [`examples/mock-steps`](examples/mock-steps)).
Random values (`7scaucgi`, `6ue382pe`) are different on every run.

| When | Error | Fix |
|---|---|---|
| `plan` or `test` with the real provider (`make naive`) | `Attempted to load application default credentials since neither credentials nor access_token was set ... No credentials loaded.` | `mock_provider "google"` in the test file |
| `mock_provider "google" {}` with nothing in it (`01-empty-mock`) | `Invalid index ... data.google_compute_zones.available.names is empty list of string` | `mock_data "google_compute_zones"` with real zone names |
| Zones mocked, provider config not (`02-zones-only`) | `Resource precondition failed ... Zone europe-west1-b is not in region 7scaucgi.` | `mock_data "google_client_config"` with `region = "europe-west1"` |
| `command = plan` asserting a computed value (`03-unknown-at-plan`) | `Unknown condition value ... not known until after the plan has been applied` | `override_during = plan` on the mock, or `command = apply` |
| `command = apply` with no mock for the service account | `Resource postcondition failed ... self.email is "5m8nbqax"` | `mock_resource "google_service_account"` with a real-looking email |
| `override_during = plan` with only `email` set, then `apply` (`04-partial-override`) | `Provider produced inconsistent final plan ... invalid new value for .name: was "jgkczdiq", but now "ijbaokqi"` | Set every computed attribute in `defaults` |
| Asserting the VM IP after a mocked apply (`05-random-ip`) | `output.instance_internal_ip is "6ue382pe"` (not an IP) | `mock_resource "google_compute_instance"` with `network_interface = { network_ip = "10.30.1.2" }` |
| Mocking a nested block as a list `[{ ... }]` | `expected an object type for attribute ".network_interface[0]" ... but found tuple` | Nested blocks are mocked per element: an object, not a list |
| `labels == { ... }` (`06-labels-object`) | `Test assertion failed ... LHS and RHS values are of different types` | `tomap({ ... })` |
| `lifecycle_rule[0].condition[0].age` | `Cannot index a set value` | `one(...lifecycle_rule[0].condition).age` |
| Expected postcondition failure in a `command = apply` run (`07-postcondition-apply`) | `Expected failure while planning ... the overall test case will be marked as a failure` | The value is known at plan, so use `command = plan` |
| New `module { source = ... }` in a run | `Module not installed` | `terraform init` again |
| `self` in a precondition | `The "self" object is not available in this context` | Use a local (`local.zone`), or a postcondition |

## What mocks do NOT prove

`tests/limits.tftest.hcl` passes with `machine_type = "e2-banana"` and `db_tier = "db-banana"`.

| Mocks prove | Mocks do NOT prove |
|---|---|
| Your HCL logic: names, labels, `count`, `for_each`, dynamic blocks | The API accepts your values (machine types, tiers, images) |
| Variable validation, preconditions, postconditions | IAM: who can create what, org policies |
| Provider schema + static validators (e.g. `direction = "SIDEWAYS"` is rejected) | Quotas, regional availability, globally unique bucket names |
| Module wiring and outputs | APIs enabled, service networking, real timings |

Mocks are the fast layer. Real `plan` against a sandbox project (or policy checks) is still the next layer.

## Cleanup

```bash
make clean   # removes the .terraform folders
```

Nothing to destroy: nothing was ever created.
