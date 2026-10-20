# Mock steps: replay the real errors

One folder per mistake, in the order you hit them while writing the tests. Each folder holds a single
test file that runs against the lab's root module.

```bash
make step STEP=01-empty-mock
# same as: terraform test -test-directory=examples/mock-steps/01-empty-mock
```

| Step | What is missing | Error |
|---|---|---|
| `01-empty-mock` | Any mock data | `Invalid index ... names is empty list of string` |
| `02-zones-only` | `google_client_config` | `Resource precondition failed ... is not in region 7scaucgi` |
| `03-unknown-at-plan` | `override_during = plan` | `Unknown condition value` |
| `04-partial-override` | All computed attributes in `defaults` | `Provider produced inconsistent final plan` |
| `05-random-ip` | `network_interface = { network_ip = ... }` | `output.instance_internal_ip is "6ue382pe"` |
| `06-labels-object` | `tomap()` | `LHS and RHS values are of different types` |
| `07-postcondition-apply` | `command = plan` | `Expected failure while planning` |

The fixed versions live in [`tests/`](../../tests). These steps are not part of `make test`.
