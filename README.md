# gcp-learning

Практика по курсу «Базы данных в GCP». Инфраструктура в Terragrunt, применяется через GitHub Actions.

## Структура

| Путь | Что | Кто применяет |
|---|---|---|
| `databases/module-0/` | Проект, billing, бюджет, SA, WIF (чистый terraform) | Админ локально, один раз |
| `databases/module-1+/` | Стеки курса (terragrunt) | CI; локально — через impersonation |
| `root.hcl` | Провайдер google, бэкенд GCS | — |
| `.github/workflows/` | `plan.yml` на PR, `apply.yml` после merge | — |

## Как применяются изменения

```
ветка → PR → plan.yml (terraform-plan) → комментарий с планом в PR
          → merge в main → apply.yml: plan → подтверждение в environment production
                                        → apply (terraform-apply)
```

GitHub Variables: `GCP_WORKLOAD_IDENTITY_PROVIDER`, `GCP_SA_PLAN`, `GCP_SA_APPLY`
(значения — `terraform output` в `databases/module-0/1-bootstrap`).

## Локально

```bash
brew install mise && mise install
gcloud auth application-default login
mise run plan     # от имени terraform-plan
mise run apply    # от имени terraform-apply
```

Модули курса после практики удаляются (`terragrunt destroy` в папке стека), чтобы не тратить кредиты.
