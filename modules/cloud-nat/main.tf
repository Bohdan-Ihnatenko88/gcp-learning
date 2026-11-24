# Outbound internet for VMs without an external IP (package updates, etc.).
# Google APIs do not need it: the subnet has Private Google Access.

resource "google_compute_router" "this" {
  project = var.project_id
  name    = var.router_name
  region  = var.region
  network = var.network_id
}

resource "google_compute_router_nat" "this" {
  project = var.project_id
  name    = var.nat_name
  region  = var.region
  router  = google_compute_router.this.name

  # Google allocates and scales the external IPs. Use MANUAL_ONLY with reserved
  # addresses when a partner allowlists your egress IPs.
  nat_ip_allocate_option = "AUTO_ONLY"

  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}
