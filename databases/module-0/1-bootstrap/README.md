# bootstrap

The foundation Terraform and CI need before they can run on their own: the state bucket,
the Terraform service accounts, Workload Identity Federation for GitHub Actions and
impersonation for people. Applied once by an admin with their own account.

Stage 1. Runs after `../0-seed`, which creates the project, the billing link and the budget.

## Access model

| Who | Signs in with | Acts as | Permissions |
|---|---|---|---|
| CI on a PR | WIF, any ref of the repository | `terraform-plan` | Read |
| CI after merge | WIF, only jobs in the GitHub environment `<apply_environment>` | `terraform-apply` | Write |
| Person: plan | `gcloud` ADC + impersonation | `terraform-plan` | Read |
| Person: apply | `gcloud` ADC + impersonation | `terraform-apply` | Write |
| Admin: bootstrap | `gcloud` ADC, own owner role | Themselves | Everything |

There are no service account keys. People and CI have the same permissions because they
use the same SAs. Audit Logs show who used an SA.

## Files

| File | Contents |
|---|---|
| `apis.tf` | Enabled APIs |
| `state.tf` | State bucket (versioning, 30-day cleanup of old versions) and SA access to it |
| `service_accounts.tf` | `terraform-plan`, `terraform-apply`, their roles, impersonation |
| `workloads.tf` | Workload SAs with project roles (`db-bastion`) and `db_operators` access to the bastion |
| `wif.tf` | WIF pool and provider, which GitHub jobs can become which SA |
| `org_policy.tf` | Ban on JSON keys (only for a project in an organization) |

`terraform-apply` has no `roles/resourcemanager.projectIamAdmin`, otherwise it could grant
itself any role. Project roles change only here, in bootstrap.

## Steps

1. Apply `../0-seed`.
2. Set the new project as the ADC quota project (API calls are billed to it):
   ```bash
   gcloud auth application-default set-quota-project <project_id>
   ```
3. `cp terraform.tfvars.example terraform.tfvars`, set `project` (= `project_id` output of
   0-seed), `repo`, `apply_environment` and yourself in `*_impersonators` (and `db_operators`
   if you are not a project owner).
4. Apply with local state:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```
5. Move the bootstrap state to the bucket:
   ```bash
   cp backend.tf.example backend.tf   # set the bucket name
   terraform init -migrate-state
   rm terraform.tfstate terraform.tfstate.backup
   ```
6. Copy `terraform output` to GitHub, Settings -> Secrets and variables -> Actions -> Variables:
   `GCP_WORKLOAD_IDENTITY_PROVIDER`, `GCP_SA_PLAN`, `GCP_SA_APPLY`.
7. Create the GitHub environment named exactly as `apply_environment`, with required
   reviewers and deployment branches limited to protected branches.
8. In production, people then lose their broad personal project roles. Owner stays with a
   small break-glass group for emergencies and bootstrap changes.

## How other stacks use it

The `google` provider and the GCS backend both read `GOOGLE_IMPERSONATE_SERVICE_ACCOUNT`,
so stacks do not name an SA in code:

```bash
gcloud auth application-default login            # once, with your own account
export GOOGLE_IMPERSONATE_SERVICE_ACCOUNT=terraform-plan@<project>.iam.gserviceaccount.com
terragrunt plan
```

The same with `terraform-apply@...` for apply. `mise run plan` / `mise run apply` set it for you.

In GitHub Actions:

```yaml
permissions:
  id-token: write   # GitHub issues no OIDC token without it
steps:
  - uses: google-github-actions/auth@<sha> # v2
    with:
      workload_identity_provider: ${{ vars.GCP_WORKLOAD_IDENTITY_PROVIDER }}
      service_account: ${{ vars.GCP_SA_PLAN }}   # GCP_SA_APPLY in the apply job
```

The apply SA is granted only to a job with `environment: <apply_environment>`: its OIDC token
has `sub = repo:<owner>/<repo>:environment:<name>`. Any other job, even on `main`, gets 403.
Required reviewers and the branch restriction are configured on the GitHub environment.
