# Private Service Access: managed databases (Cloud SQL, AlloyDB, Memorystore)
# live in a Google-owned VPC. We reserve an internal range in our VPC and
# peer it with Google's network, so instances get private IPs from that range.

resource "google_compute_global_address" "this" {
  project       = var.project_id
  name          = var.range_name
  network       = var.network_id
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  address       = var.range_address
  prefix_length = var.range_prefix_length
}

resource "google_service_networking_connection" "this" {
  network                 = var.network_id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.this.name]

  # On destroy, drop the peering instead of failing while Google still
  # holds resources in it (a deleted Cloud SQL instance lingers for days)
  deletion_policy = "ABANDON"
}
