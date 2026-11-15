# Линтер terraform: ловит ошибки до plan и без доступа к GCP.
# Запуск: mise run lint (то же самое делает CI в lint.yml)

config {
  # Проверять и локальные модули, которые вызываются из кода
  call_module_type = "local"
}

# Общие правила terraform: версии, типы переменных, неиспользуемые объявления
plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

# Правила GCP: несуществующие типы машин, регионы, неверные значения полей
plugin "google" {
  enabled = true
  version = "0.41.0"
  source  = "github.com/terraform-linters/tflint-ruleset-google"
}
