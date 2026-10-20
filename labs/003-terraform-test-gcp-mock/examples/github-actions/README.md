# GitHub Actions: `terraform test` on every pull request

[`terraform-test.yml`](terraform-test.yml) runs `fmt -check`, `init`, `validate` and `terraform test`
on each PR that touches this lab, and uploads a JUnit report.

There are **no secrets and no `google-github-actions/auth` step**: every test uses
`mock_provider "google"`, so nothing ever talks to GCP.

```bash
mkdir -p .github/workflows
cp labs/003-terraform-test-gcp-mock/examples/github-actions/terraform-test.yml .github/workflows/
```

Change `paths` and `working-directory` if your Terraform lives somewhere else.

If you later add tests that hit a real project (no `mock_provider`), keep them in a separate
workflow with Workload Identity Federation, not in the PR check.
