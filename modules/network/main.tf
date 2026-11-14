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

# Раньше стек был на модуле network из Registry
moved {
  from = module.vpc.google_compute_network.network
  to   = google_compute_network.this
}

moved {
  from = module.subnets.google_compute_subnetwork.subnetwork["europe-west2/learning-europe-west2"]
  to   = google_compute_subnetwork.this
}
