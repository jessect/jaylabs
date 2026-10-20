# Naive provider (expected to fail)

The provider block from every Azure tutorial: `features {}` and a subscription, no `metadata_host`.
azurerm then targets the **public** Azure cloud (`management.azure.com`) and logs in with whatever
account your Azure CLI is using.

`make naive` runs it with an **empty** Azure CLI profile (`AZURE_CONFIG_DIR=$(mktemp -d)`), so it can
never pick up a real login:

```text
Error: unable to build authorizer for Resource Manager API: could not configure AzureCli Authorizer:
tenant ID was not specified and the default tenant ID could not be determined: obtaining tenant ID:
obtaining account details: running Azure CLI: exit status 1: ERROR: Please run 'az login' to setup account.
```

That error is the good outcome. If you are logged in to a real Azure account in your normal shell,
the same block would plan (and apply) against that real subscription. Never run it that way.

```bash
make naive          # from the lab folder
```
