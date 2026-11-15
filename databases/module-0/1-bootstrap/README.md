# bootstrap

Фундамент проекта, без которого Terraform и CI не могут работать сами: бакет под стейт,
сервисные аккаунты Terraform, Workload Identity Federation для GitHub Actions и
impersonation для людей. Применяется админом один раз под личным аккаунтом.

Стадия 1. Запускается после `../0-seed`, который создаёт сам проект, привязку billing и бюджет.

## Модель доступа

| Кто | Как входит | От чьего имени | Права |
|---|---|---|---|
| CI на PR | WIF, любой ref репозитория | `terraform-plan` | Чтение |
| CI после merge | WIF, только джобы в GitHub environment `<apply_environment>` | `terraform-apply` | Изменения |
| Человек: plan | `gcloud` ADC + impersonation | `terraform-plan` | Чтение |
| Человек: apply | `gcloud` ADC + impersonation | `terraform-apply` | Изменения |
| Админ: bootstrap | `gcloud` ADC, личные права owner | Сам | Всё |

Ключей сервисных аккаунтов нет нигде. Права у людей и CI одинаковые, потому что они
пользуются одними и теми же SA. В Audit Logs видно, кто именно использовал SA.

## Файлы

| Файл | Что внутри |
|---|---|
| `apis.tf` | Включение API |
| `state.tf` | Бакет стейта (версии, чистка через 30 дней) + доступ SA к нему |
| `service_accounts.tf` | `terraform-plan`, `terraform-apply`, их роли, impersonation |
| `wif.tf` | Пул и провайдер WIF, кто из GitHub может стать каким SA |
| `org_policy.tf` | Запрет JSON-ключей (только если проект в организации) |

У `terraform-apply` нет `roles/resourcemanager.projectIamAdmin`: иначе он мог бы выдать себе
любые права. Роли на проект меняются только здесь, в bootstrap.

## Шаги

1. Применить `../0-seed`.
2. Указать новый проект как quota project для ADC (на него «записываются» вызовы API):
   ```bash
   gcloud auth application-default set-quota-project <project_id>
   ```
3. `cp terraform.tfvars.example terraform.tfvars`, подставить `project` (= output `project_id` из 0-seed), `repo` и себя в `*_impersonators`.
4. Применить с локальным стейтом:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```
5. Перенести стейт bootstrap в бакет:
   ```bash
   mv backend.tf.example backend.tf   # подставить имя бакета
   terraform init -migrate-state
   rm terraform.tfstate terraform.tfstate.backup
   ```
6. `terraform output` → в GitHub, Settings → Variables → Actions:
   `GCP_WORKLOAD_IDENTITY_PROVIDER`, `GCP_SA_PLAN`, `GCP_SA_APPLY`.
7. В проде после этого у людей забирают личные широкие роли на проект. Остаётся owner у
   небольшой break-glass группы для аварий и изменений bootstrap.

## Как дальше работают остальные стеки

Провайдер `google` и GCS-бэкенд оба читают переменную `GOOGLE_IMPERSONATE_SERVICE_ACCOUNT`,
поэтому в коде стеков SA не прописывается:

```bash
gcloud auth application-default login            # один раз, под своим аккаунтом
export GOOGLE_IMPERSONATE_SERVICE_ACCOUNT=terraform-plan@<project>.iam.gserviceaccount.com
terragrunt plan
```

Для apply — то же самое с `terraform-apply@…`.

В GitHub Actions:

```yaml
permissions:
  id-token: write   # без этого GitHub не выдаст OIDC-токен
steps:
  - uses: google-github-actions/auth@v2
    with:
      workload_identity_provider: ${{ vars.GCP_WORKLOAD_IDENTITY_PROVIDER }}
      service_account: ${{ vars.GCP_SA_PLAN }}   # в apply-джобе — GCP_SA_APPLY
```

Apply SA выдаётся только джобе с `environment: <apply_environment>`: у неё `sub` в OIDC-токене
`repo:<owner>/<repo>:environment:<name>`. Любая другая джоба, даже из `main`, получит 403.
Required reviewers и ограничение веток (Deployment branches → `main`) задаются в настройках
environment на GitHub.
