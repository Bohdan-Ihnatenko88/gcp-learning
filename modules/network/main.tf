resource "google_compute_network" "this" {
  project = var.project_id
  name    = var.network_name

  # Подсети задаём сами, а не по одной на каждый регион
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}

resource "google_compute_subnetwork" "this" {
  project       = var.project_id
  name          = var.subnet_name
  region        = var.region
  network       = google_compute_network.this.id
  ip_cidr_range = var.subnet_cidr

  # Доступ к Google API без внешнего IP
  private_ip_google_access = true
}

# Раньше стек был на модуле network из Registry, он создавал ресурсы через
# провайдер google-beta. moved между провайдерами не работает, поэтому старые
# записи убираем из стейта без удаления в GCP, а те же ресурсы импортируем заново.
# После apply эти блоки можно удалить.
removed {
  from = module.vpc.google_compute_network.network

  lifecycle {
    destroy = false
  }
}

removed {
  from = module.subnets.google_compute_subnetwork.subnetwork

  lifecycle {
    destroy = false
  }
}

import {
  to = google_compute_network.this
  id = "projects/${var.project_id}/global/networks/${var.network_name}"
}

import {
  to = google_compute_subnetwork.this
  id = "projects/${var.project_id}/regions/${var.region}/subnetworks/${var.subnet_name}"
}
