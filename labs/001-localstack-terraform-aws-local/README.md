# Lab 001 — Terraform on LocalStack and Moto: AWS on your laptop for $0

> 🎬 **Video:** coming soon
>
> **Tested with:** Terraform 1.16.6 · AWS provider 6.69.1 · LocalStack 2026.10.0 · Moto 5.2.4 · AWS CLI 2.38.2 · Docker 29.9.1 · Ubuntu 24.04 (WSL2)

Build a small AWS stack with Terraform **without an AWS account and without spending a cent**, first on
[LocalStack](https://www.localstack.cloud/) and then on [Moto](https://github.com/getmoto/moto) as a fully
open-source fallback. Along the way you hit (and fix) the real errors you will meet in practice.

## Goal

- Point the Terraform AWS provider at a local endpoint (`http://localhost:4566`).
- Create S3, DynamoDB, SQS (with a dead-letter queue), a VPC with an EC2 instance, an SSM parameter and a Secrets Manager secret.
- Prove it works with the AWS CLI (`awslocal`), then tear everything down.
- Compare LocalStack and Moto side by side.

## Architecture

```text
                       terraform apply
                             │
                             ▼
             http://localhost:4566  (LocalStack or Moto)
 ┌───────────┬───────────┬──────────────┬───────────────┬─────────────────┐
 │    S3     │ DynamoDB  │     SQS      │   VPC + EC2   │  SSM + Secrets  │
 │  bucket   │  orders   │ orders ────► │  10.0.0.0/16  │ /jaylabs/lab001 │
 │ versioned │ (PK: id)  │ orders-dlq   │ subnet, SG,   │ db-credentials  │
 │           │           │ (3 receives) │ t3.micro      │ (random pwd)    │
 └───────────┴───────────┴──────────────┴───────────────┴─────────────────┘
```

| File | What it does |
|---|---|
| `providers.tf` | AWS provider with fake `test` credentials and every endpoint pointed at `var.endpoint` |
| `main.tf` | S3 bucket + versioning, DynamoDB table `orders`, SQS queue `orders` with a dead-letter queue |
| `network.tf` | VPC, subnet, security group (SSH only from inside the VPC) |
| `ec2.tf` | `t3.micro` instance with an Amazon Linux 2023 AMI found by `data "aws_ami"` |
| `config.tf` | SSM parameter `/jaylabs/lab001/app_env` and a Secrets Manager secret with a generated password |
| `docker-compose.yml` | LocalStack container on `127.0.0.1:4566` |
| `examples/naive-provider/` | The "just set a region" provider, to show what happens without local endpoints |
| `examples/tflocal-demo/` | Plain provider block deployed with `tflocal` |
| `terraform.tfvars.example` | Copy to `terraform.tfvars` to change region, endpoint or name prefix |
| `scripts/check.sh` | Smoke test of every resource with `awslocal` |
| `Makefile` | Shortcuts: `make up`, `make moto-up`, `make check`, `make destroy`, `make down`, `make naive` |

## Prerequisites

Tested on Ubuntu 24.04 (WSL2) and Ubuntu 22.04.

| Tool | Version tested |
|---|---|
| Docker Engine + Compose plugin | 29.9.1 / v5.6.0 |
| Terraform | 1.16.6 (AWS provider 6.69.1, random 3.9.1) |
| AWS CLI v2 | 2.38.2 |
| Python 3 + venv | for `awslocal`, `tflocal` and `moto` (see `requirements.txt`) |
| LocalStack | 2026.10.0, free account + auth token |
| Moto | 5.2.4 |

```bash
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
```

## Estimated cost

**$0.** Nothing is created in a real AWS account. LocalStack needs a free account
(its free plan is for non-commercial use, check their terms). Moto is open source.

## Part 1 — LocalStack

```bash
cp .env.example .env            # then add your token: LOCALSTACK_AUTH_TOKEN=ls-...
make up                         # docker compose up -d + wait until healthy
terraform init
terraform apply -auto-approve   # ~55 s, 13 resources
make check                      # S3, DynamoDB, SQS, EC2, SSM, Secrets Manager
terraform destroy -auto-approve # ~90 s
make down
```

Get the token at <https://app.localstack.cloud> (Settings → Auth Tokens). Never commit `.env`.

## Part 2 — Moto (open-source fallback)

Moto listens on the same port, so the Terraform code does not change.

```bash
make moto-up                    # moto_server -p 4566 in the background
terraform apply -auto-approve
make check
terraform destroy -auto-approve
make moto-down
```

## Real errors you will hit (and the fix)

| When | Error | Fix |
|---|---|---|
| LocalStack started without a token | Container exits with code 55: `License activation failed! ... No credentials were found in the environment.` | Put `LOCALSTACK_AUTH_TOKEN` in `.env` |
| Provider with only `region` + fake keys (`make naive`) | `api error InvalidClientTokenId: The security token included in the request is invalid.` (403 from the **real** AWS STS) | Add `endpoints {}` and the `skip_*` flags (see `providers.tf`), or use `tflocal` |
| `terraform plan` with the emulator stopped | `dial tcp 127.0.0.1:4566: connect: connection refused` after ~1 min of retries | Start the emulator again |
| Emulator restarted | Everything is gone: `Plan: N to add` | Re-apply. Full persistence is a paid LocalStack feature; Moto is in-memory only |
| `terraform destroy` after uploading a file | `409 ... BucketNotEmpty: The bucket you tried to delete is not empty` | `force_destroy = true` on the versioned bucket |
| `apply` right after `destroy` | `InvalidRequestException: You can't create this secret because a secret with this name is already scheduled for deletion.` (Moto: `ResourceExistsException`) | `recovery_window_in_days = 0` (lab only, keep the 30-day default in real accounts) |

### Your secret is in plain text in the state file

```bash
grep -n '"result"\|secret_string' terraform.tfstate
```

The generated password shows up in clear text. That is why `*.tfstate*` is in `.gitignore` and why real
projects use an encrypted remote backend.

## Bonus — `tflocal`

`tflocal` (from `terraform-local`) injects the local endpoints for you, so a plain provider block is enough
(full example in [`examples/tflocal-demo`](examples/tflocal-demo)):

```hcl
provider "aws" {
  region = var.region
}
```

```bash
cd examples/tflocal-demo
tflocal init && tflocal apply -auto-approve
```

## LocalStack vs Moto

| | LocalStack | Moto |
|---|---|---|
| Setup | Docker + free account/token | `pip install "moto[server]"` |
| Account ID | `000000000000` | `123456789012` |
| SQS queue URL | `http://sqs.us-east-1.localhost.localstack.cloud:4566/000000000000/...` | `http://localhost:4566/123456789012/...` |
| Error fidelity | Matches real AWS (secret "scheduled for deletion") | Sometimes a different exception |
| State after restart | Lost (persistence is a paid feature) | Lost (in-memory) |
| Apply / destroy time | ~55 s / ~90 s | ~55 s / ~90 s |

Most of the time goes to SQS: the AWS provider waits ~25 s per queue on create and ~42 s on delete,
on both emulators. EC2 takes ~10 s; everything else is near-instant.

## Cleanup

```bash
terraform destroy -auto-approve
make down                       # docker compose down -v + remove ./volume
```
