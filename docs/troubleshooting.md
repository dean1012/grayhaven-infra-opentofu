# Troubleshooting

This document captures known transient operational issues and safe recovery
patterns for Grayhaven OpenTofu runs.

## Transient Provider API Errors

Cloud provider APIs can occasionally return transient errors during resource
creation or update. One example is a provider-side lock or transaction deadlock
while OpenTofu is creating several resources at once. These errors can affect
different resource types and do not necessarily mean the configuration is
wrong.

DNS records are ordered by type in this repository to reduce provider-side DNS
transaction contention. If the provider still returns a transient deadlock, use
the same retry pattern as other provider API errors.

When this happens:

1. Run `tofu plan` again and review the remaining changes.
2. If the plan is still expected, run `tofu apply` again.
3. If the same provider-side concurrency error repeats, retry the apply with
   lower parallelism:

   ```bash
   tofu apply -parallelism=1
   ```

OpenTofu records successfully created resources in state before the failed
operation returns. A follow-up plan should normally show only the resources
that still need to be created or updated.

## DigitalOcean Permission Errors

DigitalOcean can reject an OpenTofu operation when the active token is missing
one of the required permissions. The exact message depends on the affected
resource, but it may resemble this example:

```text
Error: GET https://api.digitalocean.com/v2/example-resource: 403
The access token does not have the required scope for this request.
```

DigitalOcean token scopes cannot be updated in place. Resolve this by creating
a replacement token with the missing permission included, updating
`TF_VAR_do_token`, validating the new token with `tofu plan`, and revoking the
old token after validation. Follow
[DigitalOcean Token Rotation](operations.md#digitalocean-token-rotation) for
the full rotation procedure.

If the missing permission is required for normal repository operation, update
the token scope table in [Setup](setup.md#create-a-digitalocean-token) so the
documentation remains accurate.
