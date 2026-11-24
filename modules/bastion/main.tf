# VM without an external IP for reaching private databases. People get in with
# SSH through IAP (Google account + OS Login), the Auth Proxy on the VM connects
# to Cloud SQL as the VM's service account (IAM authentication, no password).
#
# Production would bake the tools into an image (Packer) instead of installing
# them at boot.

resource "google_compute_instance" "this" {
  project      = var.project_id
  name         = var.name
  zone         = var.zone
  machine_type = var.machine_type
  labels       = var.labels

  boot_disk {
    initialize_params {
      # Image family: new VMs get the latest image, existing ones are not replaced
      image = "debian-cloud/debian-13"
      size  = 10
      type  = "pd-balanced"
    }
  }

  network_interface {
    subnetwork = var.subnet_id
    # No access_config block = no external IP
  }

  service_account {
    email = var.service_account_email
    # Access is limited by the SA's IAM roles, not by scopes
    scopes = ["cloud-platform"]
  }

  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  metadata = {
    enable-oslogin         = "TRUE" # SSH keys bound to Google accounts, access via IAM
    block-project-ssh-keys = "TRUE"
    serial-port-enable     = "FALSE"

    # In metadata, not metadata_startup_script: a change is applied in place on
    # the next boot instead of recreating the VM
    startup-script = templatefile("${path.module}/startup.sh.tftpl", {
      postgres_client_version = var.postgres_client_version
      proxy_version           = var.proxy_version
      proxy_sha256            = var.proxy_sha256
      instance_connection     = var.cloudsql_connection_name
    })
  }

  # Changing the machine type requires a stop
  allow_stopping_for_update = true
}

# IAP TCP forwarding comes from this Google range. Only to this VM, only port 22.
resource "google_compute_firewall" "iap_ssh" {
  project   = var.project_id
  name      = "${var.name}-allow-iap-ssh"
  network   = var.network_id
  direction = "INGRESS"

  source_ranges           = ["35.235.240.0/20"]
  target_service_accounts = [var.service_account_email]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  log_config {
    metadata = "EXCLUDE_ALL_METADATA"
  }
}
