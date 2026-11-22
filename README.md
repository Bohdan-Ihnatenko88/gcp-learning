# gcp-learning

Hands-on project for the "Databases in GCP" course: a GCP project built the way production
infrastructure is built. Terraform/Terragrunt, every change through a pull request, applied by
GitHub Actions after manual approval, no service account keys.

Setup from scratch: [docs/SETUP.md](docs/SETUP.md).

## What creates what

| Folder | Resources | Applied by |
|---|---|---|
| [`databases/module-0/0-seed`](databases/module-0/0-seed) | Project, billing link, budget alert | Admin, locally |
| [`databases/module-0/1-bootstrap`](databases/module-0/1-bootstrap) | APIs, state bucket, `terraform-plan` / `terraform-apply` SAs, Workload Identity Federation | Admin, locally |
| [`databases/module-1/apis`](databases/module-1/apis) | Compute and Service Networking APIs | CI |
| [`databases/module-1/network`](databases/module-1/network) | VPC `learning-vpc`, subnet `10.10.0.0/24` | CI |
| [`databases/module-1/private-service-access`](databases/module-1/private-service-access) | Reserved range `10.20.0.0/20` + peering with Google services | CI |
| [`databases/module-2/apis`](databases/module-2/apis) | Cloud SQL Admin and Secret Manager APIs | CI |
| [`databases/module-2/cloud-sql-postgres`](databases/module-2/cloud-sql-postgres) | Cloud SQL PostgreSQL 17, private IP only, database `app`, postgres password in Secret Manager | CI |
| [`modules/`](modules) | Terraform code the stacks above call | - |
| [`root.hcl`](root.hcl) | Shared provider and GCS state backend for all stacks | - |
| [`.github/workflows/`](.github/workflows) | `lint` and `plan` on PRs, `apply` after merge | - |

## Dependencies

Each stack reads the outputs of the one it depends on, so they are created top to bottom
and destroyed bottom to top.

```mermaid
flowchart TD
    seed["0-seed<br/>project, billing, budget"]
    boot["1-bootstrap<br/>state bucket, SAs, WIF"]
    apis["apis<br/>compute, servicenetworking"]
    vpc["network<br/>VPC + subnet 10.10.0.0/24"]
    psa["private-service-access<br/>range 10.20.0.0/20 + peering"]
    apis2["module-2 apis<br/>sqladmin, secretmanager"]
    sql[("cloud-sql-postgres<br/>private IP from 10.20.0.0/20")]
    db[("AlloyDB / Redis")]

    seed --> boot
    boot -->|"CI can sign in"| apis
    apis --> vpc
    vpc -->|network_id| psa
    vpc -->|network_id| sql
    psa -->|range_name| sql
    apis2 --> sql
    psa -.->|next modules| db

    classDef admin fill:#fde2e2,stroke:#c0392b
    classDef ci fill:#e3f1fd,stroke:#2471a3
    classDef planned stroke-dasharray: 5 5
    class seed,boot admin
    class apis,vpc,psa,apis2,sql ci
    class db planned
```

Red: applied by an admin locally. Blue: applied by CI. Dashed: next course modules.

## How a change gets applied

```mermaid
flowchart LR
    pr["PR"] --> lint["lint<br/>fmt, tflint, trivy"]
    pr --> plan["plan<br/>as terraform-plan<br/>result in PR comment"]
    lint --> merge["merge to main"]
    plan --> merge
    merge --> approve["approval in<br/>Production environment"]
    approve --> apply["apply<br/>as terraform-apply"]
```
