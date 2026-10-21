# Lab 002 — Run Azure Locally: Terraform + Topaz

> 🎬 **Video:** coming soon
>
> **Tested with:** Terraform 1.16.6 · azurerm provider 4.67.0 · random 3.9.1 · Topaz v1.10.222-preview · Azure CLI 2.91.0 · Docker 29.9.1 · Ubuntu 24.04

Build a small Azure stack with Terraform **without an Azure subscription and without spending a cent**.
The real `azurerm` provider runs a real `terraform apply` against [Topaz](https://github.com/TheCloudTheory/Topaz),
an Azure emulator in one Docker container: Resource Manager, Entra ID login, Storage, Key Vault, Service Bus,
networking and more, on your machine. Along the way you hit (and fix) the real errors you will meet in practice.

## Goal

- Point the `azurerm` provider at a local cloud with one setting: `metadata_host = "topaz.local.dev:8899"`.
- Create a resource group, a storage account with a blob container and a queue, a VNet with a subnet and an NSG,
  a Key Vault (RBAC) with a generated secret, a Service Bus namespace + queue and a Log Analytics workspace.
- Prove it works with the Azure CLI (`az`), then tear everything down.

## Architecture

```text
                        terraform apply                    az (Azure CLI)
                               │                                 │
              metadata_host = topaz.local.dev:8899               │  cloud "Topaz"
                               ▼                                 ▼
       ┌──────────────── Topaz container (127.0.0.1) ─────────────────────────────────┐
       │  :8899 Resource Manager + Entra ID   :443/:8898 Key Vault   :8891 Storage    │
       └──────────────────────────────────────────────────────────────────────────────┘
 rg-jaylabs-lab002
 ┌──────────────────┬───────────────────┬──────────────────┬──────────────┬─────────────────┐
 │ stjaylabslab002  │ vnet 10.20.0.0/16 │ kv-jaylabs-lab002│ sb-jaylabs-  │ log-jaylabs-    │
 │ └ uploads (blob) │ └ snet-app /24    │ (RBAC)           │   lab002     │   lab002        │
 │ └ orders (queue) │   └ nsg: 443 in   │ └ db-password    │ └ orders     │ PerGB2018, 30 d │
 └──────────────────┴───────────────────┴──────────────────┴──────────────┴─────────────────┘
```

| File | What it does |
|---|---|
| `providers.tf` | `azurerm = 4.67.0` with `metadata_host`, the fixed Topaz subscription and `resource_provider_registrations = "none"` |
| `variables.tf` | `metadata_host`, `subscription_id`, `location`, `project` |
| `main.tf` | Resource group, storage account (TLS 1.2), private blob container `uploads`, queue `orders`, Log Analytics workspace |
| `network.tf` | VNet, subnet, NSG (HTTPS in), NSG ↔ subnet association |
| `keyvault.tf` | RBAC Key Vault, "Key Vault Administrator" for you, `random_password` stored as secret `db-password` |
| `servicebus.tf` | Service Bus namespace (Standard) + queue `orders` |
| `outputs.tf` | Names and endpoints used by `scripts/check.sh` |
| `docker-compose.yml` | Topaz on `127.0.0.1` (ports 443, 8899, 8898, 8891) with subscription `00000000-0000-0000-0000-000000000001` |
| `topaz-cloud.json` | Topaz endpoints for `az cloud register` (from the Topaz repo) |
| `env.sh` | `source env.sh`: a separate Azure CLI profile in `.azure/` plus the CA bundle for `az` |
| `scripts/check.sh` | Smoke test of every resource with `az` |
| `examples/naive-provider/` | The tutorial provider block (no `metadata_host`), run with an empty `az` profile |
| `examples/azurerm-v5/` | Same settings on azurerm 5.x, to reproduce error 3 |
| `terraform.tfvars.example` | Copy to `terraform.tfvars` to change the defaults |
| `Makefile` | `make up`, `make hosts`, `make cert`, `make login`, `make apply`, `make check`, `make plan`, `make destroy`, `make down`, `make naive`, `make v5` |

## Prerequisites

| Tool | Version tested |
|---|---|
| Docker Engine + Compose plugin | 29.9.1 / v5.6.0 |
| Terraform | 1.16.6 (azurerm 4.67.0, random 3.9.1) |
| Azure CLI | 2.91.0 (avoid 2.86.0, see the Topaz troubleshooting page) |
| Topaz | v1.10.222-preview (`thecloudtheory/topaz-host` image, ~590 MB) |
| make, curl, jq, sudo | any |

No Azure account, no LocalStack token. Install the Azure CLI with
`curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash`.

**Your real Azure login is never used.** Every `make` target and `source env.sh` set `AZURE_CONFIG_DIR=./.azure`,
a separate Azure CLI profile inside this folder (git-ignored). Your normal `~/.azure` is not read or changed.
Topaz ships a built-in fake user (`topazadmin@topaz.local.dev` / `admin`); it only exists inside the container.

## Estimated cost

**$0.** Nothing is created in Azure. Topaz is free for non-commercial use and for companies with up to
$1 million in annual revenue; commercial licences start at $49 per seat per year (check their pricing page).
The repository is Apache-2.0 today; dual licensing starts with Topaz 1.11.

## Run it

```bash
make up                         # docker compose up -d + wait until healthy (first pull ~590 MB)
make hosts                      # one time, sudo: topaz.local.dev + the vault/storage/bus names -> 127.0.0.1
make cert                       # one time, sudo: copy topaz.crt out of the container and trust it
source env.sh                   # this shell: lab-only az profile + CA bundle
make login                      # az cloud register/set Topaz + az login with the built-in fake user
terraform init
make apply                      # ~5 min, 15 resources (terraform apply -parallelism=1)
make check                      # Storage, Key Vault, Service Bus, network, Log Analytics via az
make plan                       # 3 in-place updates that never go away (see "does NOT prove")
make destroy                    # ~80 s
make down
```

`make hosts` adds one line to `/etc/hosts`. If your system regenerates `/etc/hosts` (some setups do on restart),
run `make hosts` again. If you change `project`, the names in the Makefile change with it.

## Real errors you will hit (and the fix)

| # | When | Error | Fix |
|---|---|---|---|
| 1 | Apply before `make hosts` | `waiting for Key Vault ... to become available: connecting to "https://kv-jaylabs-lab002.vault.topaz.local.dev:8898": ... dial tcp: lookup kv-jaylabs-lab002.vault.topaz.local.dev on 8.8.8.8:53: no such host` | `make hosts`. Each vault, storage account and namespace gets its own hostname |
| 2 | Topaz certificate not trusted | Terraform: `retrieving metadata from endpoint "https://topaz.local.dev:8899": ... tls: failed to verify certificate: x509: certificate signed by unknown authority`. `az`: `[SSL: CERTIFICATE_VERIFY_FAILED] certificate verify failed: self-signed certificate` | `make cert` (OS store, used by Terraform) **and** `REQUESTS_CA_BUNDLE` from `env.sh` (az ships its own CA bundle) |
| 3 | Latest provider, `azurerm ~> 5.0` (`make v5`) | `retrieving migration status for Storage Account ...: unexpected status 404 (404 Not Found) with response: {"error":{"code":"EndpointNotFound", ... /storageAccounts/stjaylabslab002v5/accountMigrations/default'"}}` | Pin `azurerm = 4.67.0`, the version Topaz is tested with |
| 4 | `metadata_host = "https://topaz.local.dev:8899"` | `retrieving metadata from endpoint "https://https://topaz.local.dev:8899": ... dial tcp: lookup https on 8.8.8.8:53: no such host` | Host and port only, no scheme |
| 5 | RBAC Key Vault without a data-plane role for you | `retrieving 'contact' for KeyVault: keyvault.BaseClient#GetCertificateContacts: Failure responding to request: StatusCode=401` | Owner is not enough for secrets (same as real Azure). Grant "Key Vault Administrator" **before** the vault exists (`depends_on`), because azurerm reads the vault's data plane while creating it |
| 6 | That role assignment at resource-group scope | `role_definition_name`: `listing role definitions: unexpected status 404 ... EndpointNotFound ... /resourceGroups/rg-jaylabs-lab002/providers/Microsoft.Authorization/roleDefinitions`. With a role id: `Still creating... [10m00s elapsed]` (Topaz log: `... roleAssignments/... has no corresponding endpoint assigned`) | Topaz only reads role assignments at subscription scope today. The lab assigns at subscription scope, by role id |
| 7 | Plain `terraform apply` (10 in parallel) | Random resources fail with `500`: `'{' is invalid after a single JSON value. Expected end of data.` Topaz log: `Failed to deserialize DNS entries file ... Content: '{"Services":{}} {` | Topaz corrupts its own registry under parallel writes. `make apply` uses `-parallelism=1`. Once it happened: `make down && make up` |
| 8 | `make naive` (no `metadata_host`) | `could not configure AzureCli Authorizer: ... running Azure CLI: exit status 1: ERROR: Please run 'az login' to setup account.` | Good: the lab runs it with an empty profile. With a real login it would target your **real** subscription |
| 9 | `make down` then `make up` | `# azurerm_resource_group.this has been deleted` ... `Plan: 14 to add, 0 to change, 0 to destroy.` | State lives in the container. `docker compose restart` keeps it; `down` deletes it. Re-apply |

### Your secret is in plain text in the state file

```bash
grep -n '"result"' terraform.tfstate
```

The generated password shows up in clear text. That is why `*.tfstate*` is in `.gitignore` and why real
projects use an encrypted remote backend.

## What Topaz does NOT prove

- **Drift-free plans.** Right after apply, `make plan` shows `Plan: 0 to add, 3 to change`: Topaz returns
  `tenant_id = 00000000-...` for the vault, `https_traffic_only_enabled = false` for the storage account and
  no `private_endpoint_vnet_policies` for the VNet. On real Azure the same code plans clean.
- **Real permissions.** One built-in admin user, object id `00000000-0000-0000-0000-000000000000`.
  RBAC is checked on Key Vault data, but Entra ID, Conditional Access and policy are not Azure's.
- **Names and quotas.** `stjaylabslab002` and `kv-jaylabs-lab002` are globally unique in real Azure and may
  already be taken. No regional capacity, SKU availability or subscription limits.
- **The latest provider.** Topaz is tested with azurerm 4.67.0; 5.x already breaks storage accounts.
- **Timing and runtime.** Apply times here come from azurerm's 10 s polling, not from Azure. Nothing really
  runs: no billing, no metrics, no traffic through the VNet or the NSG.
- **Data-plane depth.** Service Bus queues exist, but `az` cannot send messages; use an SDK. Blob, queue
  and Key Vault data plane do work.

## Why not LocalStack for Azure?

LocalStack ships `localstack/localstack-azure` (preview). It needs a LocalStack account with an auth token and
Azure access added by their support team. Without a token the container exits with code 55:
`License activation failed! ... No credentials were found in the environment.`
Topaz needs no account.

## Cleanup

```bash
make destroy
make down                        # docker compose down -v: Topaz and all its data are gone
sudo sed -i '/jaylabs-lab002-topaz/d' /etc/hosts                       # optional
sudo rm /usr/local/share/ca-certificates/topaz.crt && sudo update-ca-certificates --fresh  # optional
rm -rf .azure topaz.crt
```
