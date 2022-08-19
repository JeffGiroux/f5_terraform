# Networking

# VPC Mgmt
resource "google_compute_network" "vpc_mgmt" {
  name                    = "${var.projectPrefix}-net-mgmt"
  auto_create_subnetworks = "false"
  routing_mode            = "REGIONAL"
}
resource "google_compute_subnetwork" "vpc_mgmt_sub" {
  name          = "${var.projectPrefix}-subnet-mgmt"
  ip_cidr_range = var.mgmt_address_prefix
  region        = var.gcp_region
  network       = google_compute_network.vpc_mgmt.id
}

# VPC External
resource "google_compute_network" "vpc_ext" {
  name                    = "${var.projectPrefix}-net-ext"
  auto_create_subnetworks = "false"
  routing_mode            = "REGIONAL"
}
resource "google_compute_subnetwork" "vpc_ext_sub" {
  name          = "${var.projectPrefix}-subnet-ext"
  ip_cidr_range = var.ext_address_prefix
  region        = var.gcp_region
  network       = google_compute_network.vpc_ext.id
}

# VPC Internal
resource "google_compute_network" "vpc_int" {
  name                    = "${var.projectPrefix}-net-int"
  auto_create_subnetworks = "false"
  routing_mode            = "REGIONAL"
}
resource "google_compute_subnetwork" "vpc_int_sub" {
  name          = "${var.projectPrefix}-subnet-int"
  ip_cidr_range = var.int_address_prefix
  region        = var.gcp_region
  network       = google_compute_network.vpc_int.id
}

# Firewall Rules
resource "google_compute_firewall" "default-allow-internal-mgmt" {
  name          = "${var.projectPrefix}-default-allow-internal-mgmt"
  network       = google_compute_network.vpc_mgmt.name
  source_ranges = [var.mgmt_address_prefix]
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
  name          = "${var.projectPrefix}-default-allow-internal-ext"
  network       = google_compute_network.vpc_ext.name
  source_ranges = [var.ext_address_prefix]
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
  name          = "${var.projectPrefix}-default-allow-internal-int"
  network       = google_compute_network.vpc_int.name
  source_ranges = [var.int_address_prefix]
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
  name          = "${var.projectPrefix}-allow-mgmt"
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
  name          = "${var.projectPrefix}-allow-app"
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
  name          = "${var.projectPrefix}-allow-mgmt-1nic"
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
  name          = "${var.projectPrefix}-allow-app-ilb-probe"
  network       = google_compute_network.vpc_ext.name
  source_ranges = ["35.191.0.0/16", "130.211.0.0/22"]
  allow {
    protocol = "tcp"
    ports    = ["80", "443", "40000"]
  }
}
