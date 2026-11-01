# Модуль 0 — фундамент проекта

Стадии применяются по порядку. Чем ниже стадия, тем шире права у того, кто её запускает,
и тем реже её меняют.

| Стадия | Что создаёт | Кто запускает | Стейт |
|---|---|---|---|
| `0-seed` | Проект, привязка billing, бюджет-алерт | Админ, личный ADC | GCS, prefix `0-seed` |
| `1-bootstrap` | API, бакет стейта, SA `terraform-plan` / `terraform-apply`, WIF, impersonation | Админ, личный ADC | GCS, prefix `bootstrap` |
| дальше (модули 1+) | Сеть, базы и т.д. | CI через WIF или человек через impersonation | GCS |

Вручную делается только то, что нельзя автоматизировать: регистрация billing-аккаунта
(free trial) и вход в `gcloud`.

## Порядок

```bash
# 0. Вход (один раз)
gcloud auth login
gcloud auth application-default login
gcloud billing accounts list          # ID для 0-seed

# 1. Проект
cd 0-seed
cp terraform.tfvars.example terraform.tfvars   # project_id, billing_account
terraform init && terraform apply

# 2. Доступы
gcloud auth application-default set-quota-project <project_id>
cd ../1-bootstrap
cp terraform.tfvars.example terraform.tfvars   # project, repo, impersonators
terraform init && terraform apply

# 3. Перенос стейтов обеих стадий в созданный бакет
mv backend.tf.example backend.tf && terraform init -migrate-state
cd ../0-seed && mv backend.tf.example backend.tf && terraform init -migrate-state
```

Подробности — в README каждой стадии.
