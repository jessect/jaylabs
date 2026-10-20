# Naive provider (expected to fail)

Only `region` and fake `test` keys, no `endpoints` block. Terraform talks to the **real** AWS STS
and gets rejected:

```text
Error: Retrieving AWS account details: validating provider credentials: retrieving caller identity
from STS: operation error STS: GetCallerIdentity, https response error StatusCode: 403, RequestID: ...,
api error InvalidClientTokenId: The security token included in the request is invalid.
```

```bash
terraform init && terraform plan
```

Do not put real AWS credentials in your shell when running this.
