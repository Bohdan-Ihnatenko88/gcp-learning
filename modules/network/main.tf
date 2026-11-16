resource "google_compute_network" "this" {
  project = var.project_id
  name    = var.network_name

  # Subnets are defined explicitly, not one per region
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}

resource "google_compute_subnetwork" "this" {
  project       = var.project_id
  name          = var.subnet_name
  region        = var.region
  network       = google_compute_network.this.id
  ip_cidr_range = var.subnet_cidr

  # Access to Google APIs without an external IP
  private_ip_google_access = true
}
