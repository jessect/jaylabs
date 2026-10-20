# azurerm 5.x against Topaz (expected to fail)

Same provider settings as the lab, but `version = "~> 5.0"`. The resource group is created; the
storage account is created too, then azurerm 5.x reads its migration status, an API Topaz does not
emulate yet:

```text
Error: encoding Storage Account (...): retrieving migration status for Storage Account (...):
unexpected status 404 (404 Not Found) with response: {"error":{"code":"EndpointNotFound","message":
"Endpoint was not found for the request 'GET' '/subscriptions/00000000-0000-0000-0000-000000000001/
resourceGroups/rg-jaylabs-lab002-v5/providers/Microsoft.Storage/storageAccounts/stjaylabslab002v5/
accountMigrations/default'"}}
```

`terraform destroy` fails the same way (it refreshes the account first), so clean up with the CLI:

```bash
make v5             # from the lab folder: reproduce
make v5-clean       # az group delete + remove the local state
```

The fix is in the lab's `providers.tf`: pin `hashicorp/azurerm = 4.67.0`, the version Topaz is tested with.
