# Lab 002 — Run Azure Locally: Terraform + Mock Provider

> 🎬 **Video:** coming soon
>
> **Tested with:** Terraform 1.16.6 · azurerm provider 5.10.0 · random provider 3.9.1 · Ubuntu 24.04 (WSL2)

Test a realistic Azure stack with Terraform **without an Azure subscription, without credentials and without
spending a cent**. There is no Azure emulator for the `azurerm` provider, so this lab uses Terraform's own
test framework: `terraform test` with `mock_provider "azurerm"`. Along the way you hit (and fix) the real
errors you will meet in practice, and you see exactly what a mock can and cannot prove.

## Goal

- Write an Azure root module: resource group, storage account + private container, VNet + subnet + NSG,
  App Service plan + Linux web app, Key Vault + secret + RBAC role assignments.
- Unit-test it in plan mode: naming convention, mandatory tags, NSG rules, storage and web app hardening.
- Test bad input with `expect_failures`: variable validations and a lifecycle precondition.
- Test the wiring in apply mode with `mock_resource`, `mock_data` and `override_resource`.
- Learn the blind spots: what passes on mocks and would still fail on real Azure.

## Architecture

```text
                    terraform test   (no login, no network)
                             │
              mock_provider "azurerm"  ← tests/mocks/azurerm.tfmock.hcl
                             │
 rg-jaylabs-dev ─────────────┼──────────────────────────────────────────────────────────┐
 │                           ▼                                                          │
 │  stjaylabsdev          vnet-jaylabs-dev 10.20.0.0/16      asp-jaylabs-dev (Linux B1) │
 │  TLS1_2, HTTPS only    └ snet-app 10.20.1.0/24 ◄──────── app-jaylabs-dev (node 22)   │
 │  └ uploads (private)     └ nsg-app-jaylabs-dev            │ managed identity         │
 │                            allow-https-in   100 (443)     │ DB_PASSWORD = KV ref     │
 │                            deny-all-in     4096           ▼                          │
 │                                                   kv-jaylabs-dev (RBAC)              │
 │                                                   └ db-password ◄─ random_password   │
 │                                                   Secrets Officer → you (deployer)   │
 │                                                   Secrets User    → web app          │
 └──────────────────────────────────────────────────────────────────────────────────────┘
```

| File | What it does |
|---|---|
| `providers.tf` | `azurerm ~> 5.0` and `random ~> 3.6`, plain `provider "azurerm" { features {} }` |
| `variables.tf` | `project`, `environment`, `location`, `address_space`, `allowed_https_cidrs`, `app_service_sku`, `tags`, with validations |
| `main.tf` | Naming/tag locals, resource group, storage account (LRS in dev, GRS in prod), private container |
| `network.tf` | VNet, subnet delegated to App Service, NSG (HTTPS in, deny everything else), NSG association |
| `app.tf` | App Service plan + Linux web app (HTTPS only, TLS 1.2, no FTP, managed identity, Key Vault reference). Precondition: no Basic plan in prod |
| `keyvault.tf` | Key Vault (RBAC, purge protection in prod), two role assignments, generated password stored as a secret |
| `outputs.tf` | Resource group, storage account, web app URL, Key Vault URI, subnet id |
| `tests/unit.tftest.hcl` | 6 plan-mode runs: names, tags, storage, NSG, web app, prod |
| `tests/validation.tftest.hcl` | 6 runs with `expect_failures`: bad project, environment, CIDRs, SKU, prod on Basic |
| `tests/apply.tftest.hcl` | 3 apply-mode runs with `override_resource`: URL output, subnet wiring, RBAC to the right identity |
| `tests/mocks/azurerm.tfmock.hcl` | Shared `mock_data` / `mock_resource` defaults (UUIDs and well-formed Azure ids) |
| `examples/naive-provider/` | A test **without** mocks: the real provider tries to log in |
| `examples/common-mistakes/` | The 7 errors from the video, one file each, all failing on purpose |
| `examples/mock-blind-spots/` | Tests that pass on mocks and would fail on real Azure |
| `Makefile` | `make test`, `make test-verbose`, `make naive`, `make mistakes`, `make mistake N=02`, `make blind-spots`, `make break` ... (`make` lists them all) |

## Prerequisites

| Tool | Version tested |
|---|---|
| Terraform | 1.16.6 (`mock_provider` needs ≥ 1.7; the lab asks for ≥ 1.9) |
| azurerm provider | 5.10.0 (downloaded by `terraform init`) |
| random provider | 3.9.1 |
| make, bat (optional) | any |

No Azure CLI, no Azure account, no Docker.

## Estimated cost

**$0.** Nothing is ever sent to Azure. `terraform test` only talks to the mocked provider.

## Run it

```bash
make init        # terraform init: downloads azurerm + random (~60 MB)
make validate    # Success! The configuration is valid.
make test        # 15 passed, 0 failed, in ~3 s
```

```text
tests/apply.tftest.hcl... pass
tests/unit.tftest.hcl... pass
tests/validation.tftest.hcl... pass

Success! 15 passed, 0 failed.
```

Watch a test catch a mistake:

```bash
make break       # the NSG now opens port 22 instead of 443
make test-unit   # run "nsg_only_opens_https"... fail
make unbreak
```

## How the mocks work

```hcl
mock_provider "azurerm" {
  source = "./tests/mocks"     # loads tests/mocks/*.tfmock.hcl
}
```

- Every computed attribute (ids, hostnames, `tenant_id` ...) becomes a **random 8-character string**.
- The provider **schema** is still enforced, and so are some of its validations (UUIDs, Azure resource ids).
- `mock_data` / `mock_resource` set defaults for every instance of a type (shared in `tests/mocks/`).
- `override_resource` / `override_data` set values for one specific address, inside one test file or run.
- In `command = plan` runs computed values are **unknown**: assert on them in apply-mode runs.

## Real errors you will hit (and the fix)

Every one of them is reproducible with `make mistakes`, or one at a time with `make mistake N=01` ... `N=07`
(see [`examples/common-mistakes`](examples/common-mistakes)).

| When | Error | Fix |
|---|---|---|
| `provider "azurerm" {}` | `The argument "features" is required, but no definition was found.` (`terraform validate` still says valid) | Add `features {}` |
| `terraform test` without `mock_provider` (`make naive`) | `unable to build authorizer for Resource Manager API: could not configure AzureCli Authorizer ... exec: "az": executable file not found in $PATH` | `mock_provider "azurerm"` in the test file |
| Bare `mock_provider "azurerm" {}` | `expected "tenant_id" to be a valid UUID, got pv2ogmw5` | `mock_data "azurerm_client_config"` with UUIDs |
| Asserting on an id in `command = plan` | `Unknown condition value ... not known until after the plan has been applied` | Move the assert to an apply-mode run (or `override_during = plan`) |
| `expect_failures` while another error happens first | `Missing expected failure ... azurerm_linux_web_app.this, was expected to report an error but did not.` | Fix the unrelated error (here: missing mocks) |
| Apply-mode run with random ids | `parsing "zaqpos05": parsing the StorageAccount ID: the number of segments didn't match` (12 errors) | `mock_resource` defaults with well-formed Azure ids |
| Asserting on a computed value | `output.web_app_url is "https://fbbcvixl"` | `override_resource` with a realistic value |
| Overriding a nested block as a list | `expected an object type for attribute ".identity[0]" ... but found tuple.` | `identity = { principal_id = "..." }` |

## What mocks do NOT prove

| A green `terraform test` with mocks does not mean... | Why |
|---|---|
| The region exists | `location = "mars-north-1"` passes (`make blind-spots`) |
| The network is valid | A /32 subnet passes; Azure needs /29+, App Service /28+ |
| Names are free | Storage accounts, Key Vaults and web apps need globally unique names |
| SKU, quota and region availability | `P0v3` may not exist in your region or your quota may be 0 |
| RBAC works | Role assignments take minutes to propagate; your identity may not be allowed to create them |
| The provider block is right | `mock_provider` replaces it: a missing `features {}` is never seen |
| Computed values are real | `terraform test -verbose` shows `access_tier = "beg10jjk"` |

Mocks prove **your logic**: names, tags, conditions, rules, wiring, validations. Use them on every commit,
then run a real `terraform plan` against a sandbox subscription before you merge.

## Going real (optional, not part of the lab)

The root module is a normal Azure configuration. With a subscription:

```bash
az login
export ARM_SUBSCRIPTION_ID=<your-subscription-id>
terraform plan
```

Names like `stjaylabsdev` are probably taken: change `project` first. This creates billable resources.

## Cleanup

```bash
make clean       # removes .terraform folders and lock files
```

`terraform test` never writes a state file: there is nothing else to clean up.
