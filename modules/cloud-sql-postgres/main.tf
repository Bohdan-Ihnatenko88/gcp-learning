# Cloud SQL for PostgreSQL with a private IP only, reachable from the VPC
# through Private Service Access. No public IP, TLS required.

resource "google_sql_database_instance" "this" {
  project          = var.project_id
  name             = var.name
  region           = var.region
  database_version = var.database_version

  # Two layers: Terraform refuses destroy, and the API refuses delete from anywhere
  deletion_protection = var.deletion_protection

  settings {
    edition           = var.edition
    tier              = var.tier
    availability_type = var.availability_type

    deletion_protection_enabled = var.deletion_protection

    disk_type             = "PD_SSD"
    disk_size             = var.disk_size_gb
    disk_autoresize       = true
    disk_autoresize_limit = var.disk_autoresize_limit_gb

    user_labels = var.labels

    ip_configuration {
      ipv4_enabled       = false
      private_network    = var.network_id
      allocated_ip_range = var.allocated_ip_range
      ssl_mode           = "ENCRYPTED_ONLY"
    }

    backup_configuration {
      enabled                        = true
      start_time                     = "02:00" # UTC
      point_in_time_recovery_enabled = true
      transaction_log_retention_days = 7

      backup_retention_settings {
        retained_backups = var.backup_retention_count
        retention_unit   = "COUNT"
      }
    }

    # Keep automated backups after the instance is deleted
    retain_backups_on_delete = true

    final_backup_config {
      enabled        = true
      retention_days = 30
    }

    maintenance_window {
      day          = 7 # Sunday
      hour         = 3 # UTC
      update_track = "stable"
    }

    insights_config {
      query_insights_enabled  = true
      query_string_length     = 1024
      record_application_tags = true
      record_client_address   = true
    }

    password_validation_policy {
      enable_password_policy      = true
      min_length                  = 16
      complexity                  = "COMPLEXITY_DEFAULT"
      disallow_username_substring = true
    }

    dynamic "database_flags" {
      for_each = merge(local.default_flags, var.database_flags)
      content {
        name  = database_flags.key
        value = database_flags.value
      }
    }
  }

  lifecycle {
    # Disk grows on its own with autoresize; do not shrink it back on the next apply
    ignore_changes = [settings[0].disk_size]
  }
}

locals {
  default_flags = {
    # People and applications sign in with IAM, not with passwords
    "cloudsql.iam_authentication" = "on"

    # Audit and troubleshooting logs (also CIS benchmark checks)
    "log_checkpoints"            = "on"
    "log_connections"            = "on"
    "log_disconnections"         = "on"
    "log_lock_waits"             = "on"
    "log_temp_files"             = "0"
    "log_min_duration_statement" = "-1"
    "log_min_messages"           = "error"
  }
}

resource "google_sql_database" "this" {
  for_each = toset(var.databases)

  project  = var.project_id
  instance = google_sql_database_instance.this.name
  name     = each.value
}

# --- Built-in postgres user ---------------------------------------------
# Break-glass only. The password is generated on every run but never stored
# in state: it goes write-only to Cloud SQL and to Secret Manager. To rotate,
# bump admin_password_version.

ephemeral "random_password" "admin" {
  length      = 32
  special     = true
  min_special = 2
  # Characters safe in a connection URI
  override_special = "-_.~"
}

resource "google_sql_user" "admin" {
  project  = var.project_id
  instance = google_sql_database_instance.this.name
  name     = "postgres"

  password_wo         = ephemeral.random_password.admin.result
  password_wo_version = var.admin_password_version

  # The postgres role owns system objects and cannot be dropped
  deletion_policy = "ABANDON"
}

resource "google_secret_manager_secret" "admin_password" {
  project   = var.project_id
  secret_id = "${var.name}-postgres-password"
  labels    = var.labels

  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }
}

resource "google_secret_manager_secret_version" "admin_password" {
  secret = google_secret_manager_secret.admin_password.id

  secret_data_wo         = ephemeral.random_password.admin.result
  secret_data_wo_version = var.admin_password_version
}

# --- IAM database users -------------------------------------------------
# user:alice@example.com -> CLOUD_IAM_USER, serviceAccount:app@... -> CLOUD_IAM_SERVICE_ACCOUNT.
# They also need roles/cloudsql.instanceUser and roles/cloudsql.client (granted in bootstrap).
# Table grants are done in SQL, not here.

resource "google_sql_user" "iam" {
  for_each = toset(var.iam_users)

  project  = var.project_id
  instance = google_sql_database_instance.this.name

  # Postgres drops ".gserviceaccount.com" from SA names
  name = startswith(each.value, "serviceAccount:") ? trimsuffix(trimprefix(each.value, "serviceAccount:"), ".gserviceaccount.com") : trimprefix(each.value, "user:")
  type = startswith(each.value, "serviceAccount:") ? "CLOUD_IAM_SERVICE_ACCOUNT" : "CLOUD_IAM_USER"
}
