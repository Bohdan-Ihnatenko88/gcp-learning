# gcp-learning

Hands-on project for the "Databases in GCP" course. Infrastructure is Terraform/Terragrunt,
changes go through pull requests and are applied by GitHub Actions with a manual approval.
No service account keys anywhere: CI signs in with Workload Identity Federation, people with
service account impersonation.

## Layout

| Path | What | Applied by |
|---|---|---|
| `databases/module-0/` | Project, billing, budget, Terraform SAs, WIF (plain terraform) | Admin, locally, once |
| `databases/module-1+/` | Course stacks (terragrunt) | CI; locally via impersonation |
| `modules/` | Terraform modules used by the stacks (`source` in `terragrunt.hcl`) | - |
| `root.hcl` | Shared google provider and GCS backend | - |
| `mise.toml` | Pinned tool versions and tasks (`plan`, `apply`, `lint`, `format`) | - |
| `.github/workflows/` | `lint.yml` and `plan.yml` on PRs, `apply.yml` after merge | - |
| `.github/dependabot.yml` | Weekly updates for SHA-pinned actions | - |

## How a change is applied

```
branch -> PR -> lint.yml: fmt, tflint, trivy (required checks)
             -> plan.yml: terragrunt plan as terraform-plan -> plan posted as a PR comment
       -> merge to main -> apply.yml: plan -> approval in the "Production" environment
                                     -> apply the same saved plan as terraform-apply
```

`databases/module-0` is excluded from plan/apply in CI: it creates the identities CI itself
runs as, so an admin applies it locally.

## Requirements

- A Google account with a billing account (the $300 free trial works).
  An organization (Cloud Identity / Workspace) is recommended, not required.
- A GitHub repository (fork or copy of this one) where you are an admin.
- macOS/Linux with [mise](https://mise.jdx.dev) and the
  [gcloud CLI](https://cloud.google.com/sdk/docs/install).
  mise installs terraform, terragrunt, tflint and trivy at the pinned versions.

## Setup

### 1. Tools and sign-in

`mise.toml` sets `CLOUDSDK_CONFIG` to `~/.config/gcloud-gcp-learning`, so inside this repo
gcloud and Terraform use their own accounts and ADC. Signing in here does not touch the
credentials you use for other projects, and leaving the folder switches back.

```bash
brew install mise
echo 'eval "$(mise activate zsh)"' >> ~/.zshrc && exec zsh   # once per machine
cd gcp-learning && mise trust && mise install

echo $CLOUDSDK_CONFIG                 # must print ~/.config/gcloud-gcp-learning
gcloud auth login                     # the Google account that owns GCP billing
gcloud auth application-default login # same account: ADC for Terraform
gcloud config list account            # check the active account
gcloud billing accounts list          # billing account ID
gcloud organizations list             # org ID, if you have one
```

This personal sign-in is used only for `module-0` and for impersonation. CI never uses it:
GitHub Actions gets short-lived tokens of `terraform-plan` / `terraform-apply` through WIF,
and `1-bootstrap` allows that only for the repository set in `repo`.

### 2. Project: `databases/module-0/0-seed`

Creates the project, links billing and sets a budget alert. Runs with your own credentials.

```bash
cd databases/module-0/0-seed
cp terraform.tfvars.example terraform.tfvars   # project_id, billing_account, org_id
terraform init && terraform apply
gcloud auth application-default set-quota-project <project_id>
```

### 3. Access: `databases/module-0/1-bootstrap`

Creates the state bucket, the `terraform-plan` / `terraform-apply` SAs, WIF for GitHub
and impersonation for you.

```bash
cd ../1-bootstrap
cp terraform.tfvars.example terraform.tfvars   # project, repo, apply_environment, impersonators
terraform init && terraform apply
```

### 4. Move both stages' state to the bucket

```bash
cp backend.tf.example backend.tf               # set the bucket name
terraform init -migrate-state && rm terraform.tfstate*
cd ../0-seed
cp backend.tf.example backend.tf
terraform init -migrate-state && rm terraform.tfstate*
```

### 5. Point the code at your project

Set `project` and `region` in [root.hcl](root.hcl) and the SA emails in [mise.toml](mise.toml).

### 6. GitHub settings

| Where | Value |
|---|---|
| Settings -> Secrets and variables -> Actions -> **Variables** | `GCP_WORKLOAD_IDENTITY_PROVIDER`, `GCP_SA_PLAN`, `GCP_SA_APPLY` from `terraform output` in `1-bootstrap` |
| Settings -> **Environments** -> `Production` | Required reviewers: you; Deployment branches: protected branches only; admin bypass off |
| Settings -> **Rules** -> ruleset on `main` | Require a pull request; required checks `format`, `tflint`, `trivy`; block deletion and force push |
| Settings -> Actions -> General | Workflow permissions: read-only; require approval for fork PRs |
| Settings -> General -> Pull Requests | Squash merge only; automatically delete head branches |
| Settings -> Advanced Security | Secret scanning with push protection; Dependabot alerts |

The environment name must match `apply_environment` in `1-bootstrap`: GCP issues the apply SA
token only to jobs in that environment.

### 7. Check

Open a PR with any change under `databases/module-1`: lint and plan should pass and the plan
appears as a comment. After merge, approve the deployment in the Actions run.

## Local commands

```bash
mise run lint      # same checks as lint.yml
mise run format    # terraform fmt + terragrunt hcl format
mise run plan      # terragrunt plan for all stacks, as terraform-plan
mise run apply     # terragrunt apply for all stacks, as terraform-apply
```

Local runs use your `gcloud` ADC and impersonate the same SAs as CI, so permissions match.

## Costs

`module-0` costs nothing beyond a few cents of storage. Destroy course stacks after practice
(`terragrunt destroy` in the stack folder) so they do not burn credits. The project has
`deletion_policy = "PREVENT"` and cannot be deleted by an accidental `terraform destroy`.
