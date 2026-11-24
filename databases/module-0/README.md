# Module 0: project foundation

Stages are applied in order. The lower the stage, the broader the permissions of whoever
runs it and the less often it changes. Step-by-step setup is in [docs/SETUP.md](../../docs/SETUP.md).

| Stage | Creates | Run by | State |
|---|---|---|---|
| `0-seed` | Project, billing link, budget alert | Admin, own ADC | GCS, prefix `0-seed` |
| `1-bootstrap` | APIs, state bucket, `terraform-plan` / `terraform-apply` SAs, WIF, impersonation | Admin, own ADC | GCS, prefix `bootstrap` |
| module-1 and later | Network, databases, etc. | CI via WIF or a person via impersonation | GCS, prefix = stack path |

Only what cannot be automated is done by hand: signing up for a billing account
(free trial) and signing in to `gcloud`.

CI does not plan or apply these stages (`plan.yml` and `apply.yml` exclude `module-0`),
but `lint.yml` checks them on every PR.

## Changing a stage

```bash
cd 1-bootstrap            # or 0-seed
terraform init
terraform plan
terraform apply
```

Both stages use your own credentials, not the Terraform SAs: bootstrap manages the roles
of those SAs, so they must not be able to change it themselves.

Details are in each stage's README.
