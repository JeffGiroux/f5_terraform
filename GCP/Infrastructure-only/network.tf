# Networking

############################ VPC and Subnets ############################

# VPC Mgmt
resource "google_compute_network" "vpc_mgmt" {
  name                    = format("%s-net-mgmt-%s", var.projectPrefix, random_id.buildSuffix.hex)
  auto_create_subnetworks = "false"
  routing_mode            = "REGIONAL"
}
resource "google_compute_subnetwork" "vpc_mgmt_sub" {
  name          = format("%s-subnet-mgmt-%s", var.projectPrefix, random_id.buildSuffix.hex)
  ip_cidr_range = var.mgmt_address_prefix
  region        = var.gcp_region
  network       = google_compute_network.vpc_mgmt.id
}

# VPC External
resource "google_compute_network" "vpc_ext" {
  name                    = format("%s-net-ext-%s", var.projectPrefix, random_id.buildSuffix.hex)
  auto_create_subnetworks = "false"
  routing_mode            = "REGIONAL"
}
resource "google_compute_subnetwork" "vpc_ext_sub" {
  name          = format("%s-subnet-ext-%s", var.projectPrefix, random_id.buildSuffix.hex)
  ip_cidr_range = var.ext_address_prefix
  region        = var.gcp_region
  network       = google_compute_network.vpc_ext.id
}

# VPC Internal
resource "google_compute_network" "vpc_int" {
  name                    = format("%s-net-int-%s", var.projectPrefix, random_id.buildSuffix.hex)
  auto_create_subnetworks = "false"
  routing_mode            = "REGIONAL"
}
resource "google_compute_subnetwork" "vpc_int_sub" {
  name          = format("%s-subnet-int-%s", var.projectPrefix, random_id.buildSuffix.hex)
  ip_cidr_range = var.int_address_prefix
  region        = var.gcp_region
  network       = google_compute_network.vpc_int.id
}

############################ Firewall Rules ############################

# Firewall Rules
resource "google_compute_firewall" "default-allow-internal-mgmt" {
  name          = format("%s-default-allow-internal-mgmt-%s", var.projectPrefix, random_id.buildSuffix.hex)
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
  name          = format("%s-default-allow-internal-ext-%s", var.projectPrefix, random_id.buildSuffix.hex)
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
  name          = format("%s-default-allow-internal-int-%s", var.projectPrefix, random_id.buildSuffix.hex)
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
  name          = format("%s-allow-mgmt-%s", var.projectPrefix, random_id.buildSuffix.hex)
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
  name          = format("%s-allow-app-%s", var.projectPrefix, random_id.buildSuffix.hex)
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
  name          = format("%s-allow-mgmt-1nic-%s", var.projectPrefix, random_id.buildSuffix.hex)
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
  name          = format("%s-allow-app-ilb-probe-%s", var.projectPrefix, random_id.buildSuffix.hex)
  network       = google_compute_network.vpc_ext.name
  source_ranges = ["35.191.0.0/16", "130.211.0.0/22"]
  allow {
    protocol = "tcp"
    ports    = ["80", "443", "40000"]
  }
}
