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

# VPC Internal
resource "google_compute_network" "vpc_int" {
  name                    = "${var.prefix}-net-int"
  auto_create_subnetworks = "false"
  routing_mode            = "REGIONAL"
}
resource "google_compute_subnetwork" "vpc_int_sub" {
  name          = "${var.prefix}-subnet-int"
  ip_cidr_range = var.cidr_range_int
  region        = var.gcp_region
  network       = google_compute_network.vpc_int.id
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

resource "google_compute_firewall" "default-allow-internal-int" {
  name          = "${var.prefix}-default-allow-internal-int"
  network       = google_compute_network.vpc_int.name
  source_ranges = [var.cidr_range_int]
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

resource "google_compute_firewall" "one_nic" {
  name          = "${var.prefix}-allow-mgmt-1nic"
  network       = google_compute_network.vpc_ext.name
  source_ranges = [var.adminSrcAddr]
  allow {
    protocol = "icmp"
  }
  allow {
    protocol = "tcp"
    ports    = ["22", "8443"]
  }
}

resource "google_compute_firewall" "app-ilb-probe" {
  name          = "${var.prefix}-allow-app-ilb-probe"
  network       = google_compute_network.vpc_ext.name
  source_ranges = ["35.191.0.0/16", "130.211.0.0/22"]
  allow {
    protocol = "tcp"
    ports    = ["80", "443", "40000"]
  }
}
