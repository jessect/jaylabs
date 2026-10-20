# Naive provider (expected to fail)

A plain `provider "azurerm" { features {} }` and a test file **without** `mock_provider`.
`terraform test` configures the real provider, which tries to log in to Azure before it can even plan:

```text
Error: unable to build authorizer for Resource Manager API: could not configure AzureCli Authorizer:
could not parse Azure CLI version: launching Azure CLI: exec: "az": executable file not found in $PATH
```

If the Azure CLI is installed but not logged in, the message ends with `Please run 'az login' to setup account.` instead.

```bash
make naive        # from the lab folder
```

`make naive` points `AZURE_CONFIG_DIR` at an empty temp folder, so an existing `az login` on your
machine is never used. Do not export real `ARM_*` credentials in your shell when running this.
