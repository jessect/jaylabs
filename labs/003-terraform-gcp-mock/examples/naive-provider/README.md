# Naive provider (expected to fail)

A `google` provider with only `project` and `region`, no credentials and no mocks.
Both `terraform plan` and `terraform test` stop before any API call:

```text
Error: Attempted to load application default credentials since neither `credentials` nor
`access_token` was set in the provider block.  No credentials loaded. To use your gcloud
credentials, run 'gcloud auth application-default login'.  Original error: google: could not find
default credentials. See https://cloud.google.com/docs/authentication/external/set-up-adc for more
information

  with provider["registry.terraform.io/hashicorp/google"],
  on main.tf line 11, in provider "google":
  11: provider "google" {
```

```bash
terraform init
terraform plan   # make naive
terraform test   # make naive-test (tests/naive.tftest.hcl has no mock_provider)
```

If you *do* have gcloud Application Default Credentials (`~/.config/gcloud/application_default_credentials.json`
or `GOOGLE_APPLICATION_CREDENTIALS`), Terraform will use them and call the real API instead.
Do not run this with real credentials in your shell.
