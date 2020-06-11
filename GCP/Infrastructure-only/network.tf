# Networking

# VPC Mgmt
resource "google_compute_network" "vpc_mgmt" {
  name                    = "${var.prefix}-net-mgmt"
  auto_create_subnetworks = "false"
  routing_mode            = "REGIONAL"
}
resource "google_compute_subnetwork" "vpc_mgmt_sub" {
  name          = "${var.prefix}-subnet-mgmt"
  ip_cidr_range = var.cidr_range_mgmt
  region        = var.gcp_region
  network       = google_compute_network.vpc_mgmt.id
}

# VPC External
resource "google_compute_network" "vpc_ext" {
  name                    = "${var.prefix}-net-ext"
  auto_create_subnetworks = "false"
  routing_mode            = "REGIONAL"
}
resource "google_compute_subnetwork" "vpc_ext_sub" {
  name          = "${var.prefix}-subnet-ext"
  ip_cidr_range = var.cidr_range_ext
  region        = var.gcp_region
  network       = google_compute_network.vpc_ext.id
}

# Firewall Rules
resource "google_compute_firewall" "default-allow-internal-mgmt" {
  name          = "${var.prefix}-default-allow-internal-mgmt"
  network       = google_compute_network.vpc_mgmt.name
  source_ranges = [var.cidr_range_mgmt]
  allow {
    protocol = "icmp"
  }
  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }
}

resource "google_compute_firewall" "default-allow-internal-ext" {
  name          = "${var.prefix}-default-allow-internal-ext"
  network       = google_compute_network.vpc_ext.name
  source_ranges = [var.cidr_range_ext]
  allow {
    protocol = "icmp"
  }
  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }
}

resource "google_compute_firewall" "mgmt" {
  name          = "${var.prefix}-allow-mgmt"
  network       = google_compute_network.vpc_mgmt.name
  source_ranges = [var.adminSrcAddr]
  allow {
    protocol = "icmp"
  }
  allow {
    protocol = "tcp"
    ports    = ["22", "443", "8443"]
  }
}

resource "google_compute_firewall" "app" {
  name          = "${var.prefix}-allow-app"
  network       = google_compute_network.vpc_ext.name
  source_ranges = [var.adminSrcAddr]
  allow {
    protocol = "icmp"
  }
  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }
}
