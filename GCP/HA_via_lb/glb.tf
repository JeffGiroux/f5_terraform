# Google Load Balancer

############################ External LB ############################

# Public IP for VIP
resource "google_compute_address" "vip1" {
  name = format("%s-vip1-%s", var.projectPrefix, random_id.buildSuffix.hex)
}

# Forwarding rule for Public IP
resource "google_compute_forwarding_rule" "vip1" {
  name                  = format("%s-forwarding-rule-%s", var.projectPrefix, random_id.buildSuffix.hex)
  load_balancing_scheme = "EXTERNAL"
  target                = google_compute_target_pool.f5vm.id
  ip_address            = google_compute_address.vip1.address
  ip_protocol           = "TCP"
  port_range            = "1-65535"
}

# Target Pool for External LB
resource "google_compute_target_pool" "f5vm" {
  name = format("%s-target-pool-%s", var.projectPrefix, random_id.buildSuffix.hex)
  instances = [
    module.bigip.self_link,
    module.bigip2.self_link
  ]
  health_checks = [
    google_compute_http_health_check.hc-ext.name,
  ]
  session_affinity = "CLIENT_IP"
}

# Health Check for Backend Pool External
resource "google_compute_http_health_check" "hc-ext" {
  name = format("%s-hc-ext-%s", var.projectPrefix, random_id.buildSuffix.hex)
  port = "40000"
}

############################ Internal LB ############################

# Forwarding rule for ILB
resource "google_compute_forwarding_rule" "vip2-internal" {
  name                  = format("%s-forwarding-rule-internal-%s", var.projectPrefix, random_id.buildSuffix.hex)
  load_balancing_scheme = "INTERNAL"
  backend_service       = google_compute_region_backend_service.f5vm.id
  ip_protocol           = "TCP"
  network               = var.extVpc
  subnetwork            = var.extSubnet
  ports                 = ["80", "443"]
}

# Backend pool for ILB
resource "google_compute_region_backend_service" "f5vm" {
  name                  = format("%s-backend-%s", var.projectPrefix, random_id.buildSuffix.hex)
  load_balancing_scheme = "INTERNAL"
  network               = var.extVpc
  backend {
    group = google_compute_instance_group.f5vm01.id
  }
  backend {
    group = google_compute_instance_group.f5vm02.id
  }
  health_checks    = [google_compute_health_check.hc-int.id]
  session_affinity = "CLIENT_IP"
  protocol         = "TCP"
}

# Instance Group for Backend Pool
resource "google_compute_instance_group" "f5vm01" {
  name = format("%s-ig1-%s", var.projectPrefix, random_id.buildSuffix.hex)
  zone = var.gcp_zone_1
  instances = [
    module.bigip.self_link
  ]
}

resource "google_compute_instance_group" "f5vm02" {
  name = format("%s-ig2-%s", var.projectPrefix, random_id.buildSuffix.hex)
  zone = var.gcp_zone_2
  instances = [
    module.bigip2.self_link
  ]
}

# Health Check for Backend Pool Internal
resource "google_compute_health_check" "hc-int" {
  name = format("%s-hc-int-%s", var.projectPrefix, random_id.buildSuffix.hex)
  tcp_health_check {
    port = "40000"
  }
}
