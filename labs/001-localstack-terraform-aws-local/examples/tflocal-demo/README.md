# tflocal demo

`tflocal` (from `terraform-local`) wraps Terraform and injects the LocalStack endpoints,
so the provider block stays as plain as it would be for real AWS.

```bash
source ../../.venv/bin/activate   # or wherever you installed requirements.txt
tflocal init
tflocal apply -auto-approve
awslocal ssm get-parameter --name /jaylabs/lab001/tflocal
tflocal destroy -auto-approve
```

`tflocal` writes `localstack_providers_override.tf` here; it is git-ignored.
