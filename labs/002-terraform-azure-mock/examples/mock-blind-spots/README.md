# Mock blind spots (all pass, all wrong)

Both runs **pass** with the mocked provider. Both would **fail** on a real subscription:

| Run | Input | Real Azure |
|---|---|---|
| `region_that_does_not_exist` | `location = "mars-north-1"` | The region does not exist |
| `subnet_too_small` | `address_space = "10.20.0.0/24"` → subnet `10.20.0.1/32` | Smallest subnet is /29; VNet integration needs /28 or larger |

```bash
make blind-spots   # from the lab folder
```

A mock knows the provider **schema** (types, required arguments, some format checks), not Azure itself.
Close the gaps you care about with `validation` blocks, and run a real `plan` before you merge.
