# Common mistakes (all fail on purpose)

Every error shown in the video, as a file you can run. Each test runs the lab module (`../..`) with
`run { module { source = "../.." } }`.

```bash
make mistakes          # all 7, from the lab folder
make mistake N=02      # just one: terraform test -filter=tests/02_random_tenant_id.tftest.hcl
```

| File | Error | Fix (see `../../tests`) |
|---|---|---|
| `01_missing_features` | `The argument "features" is required, but no definition was found.` | `provider "azurerm" { features {} }` |
| `02_random_tenant_id` | `expected "tenant_id" to be a valid UUID, got pv2ogmw5` | `mock_data "azurerm_client_config"` with UUIDs |
| `03_unknown_in_plan` | `Unknown condition value` | Assert ids in an apply-mode run, or `override_during = plan` |
| `04_expected_failure_masked` | `Missing expected failure` (an unrelated error stopped the plan first) | Fix the other error: share the mocks with `source = "./tests/mocks"` |
| `05_random_ids` | `parsing "zaqpos05": parsing the StorageAccount ID: the number of segments didn't match` | `mock_resource` with well-formed Azure ids |
| `06_random_hostname` | `output.web_app_url is "https://fbbcvixl"` | `override_resource` with a realistic `default_hostname` |
| `07_override_block_shape` | `expected an object type for attribute ".identity[0]" ... but found tuple` | `identity = { ... }`, not `identity = [{ ... }]` |

The random strings change on every run.
