# Naive provider (expected to fail)

Only `project` and `region`: no `access_token` and no `*_custom_endpoint`. Before any API call, the
provider looks for real Google credentials (Application Default Credentials) and stops:

```text
Error: Attempted to load application default credentials since neither `credentials` nor `access_token`
was set in the provider block.  No credentials loaded. To use your gcloud credentials, run
'gcloud auth application-default login'.  Original error: google: could not find default credentials.
See https://cloud.google.com/docs/authentication/external/set-up-adc for more information

  with provider["registry.terraform.io/hashicorp/google"],
  on main.tf line 10, in provider "google":
  10: provider "google" {
```

```bash
terraform init && terraform plan
```

Adding only `access_token = "owner"` is worse: `plan` passes, and `apply` sends the request to the
**real** `storage.googleapis.com`. Every service needs its `*_custom_endpoint` (see `../../providers.tf`).

If you have real ADC on your machine (`~/.config/gcloud/application_default_credentials.json` or
`GOOGLE_APPLICATION_CREDENTIALS`), Terraform will use them and call the real API. Do not run this with
real credentials in your shell.
