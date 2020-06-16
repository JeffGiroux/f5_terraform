# Google Load Balancer

###### External LB ######

# Public IP for VIP
resource "google_compute_address" "vip1" {
  name = "${var.prefix}-vip1"
}

# Forwarding rule for Public IP (aka GLB))
resource "google_compute_forwarding_rule" "vip1" {
  name                  = "${var.prefix}-forwarding-rule"
  load_balancing_scheme = "EXTERNAL"
  target                = google_compute_target_pool.f5vm.id
  ip_address            = google_compute_address.vip1.address
  ip_protocol           = "TCP"
  port_range            = "1-65535"
}

# Target Pool for External LB
resource "google_compute_target_pool" "f5vm" {
  name = "${var.prefix}-target-pool"
  instances = [
    google_compute_instance.f5vm01.self_link,
    google_compute_instance.f5vm02.self_link
  ]
  health_checks = [
    google_compute_http_health_check.hc-ext.name,
  ]
  session_affinity = "CLIENT_IP"
}

# Health Check for Backend Pool External
resource "google_compute_http_health_check" "hc-ext" {
  name = "${var.prefix}-hc-ext"
  port = "40000"
}

###### Internal LB ######

# Forwarding rule for ILB
resource "google_compute_forwarding_rule" "vip2-internal" {
  name                  = "${var.prefix}-forwarding-rule-internal"
  load_balancing_scheme = "INTERNAL"
  backend_service       = google_compute_region_backend_service.f5vm.id
  ip_protocol           = "TCP"
  network               = var.extVpc
  subnetwork            = var.extSubnet
  ports                 = ["80", "443"]
}

# Backend pool for ILB
resource "google_compute_region_backend_service" "f5vm" {
  name                  = "${var.prefix}-backend"
  load_balancing_scheme = "INTERNAL"
  network               = var.extVpc
  backend {
    group = google_compute_instance_group.f5vm.id
  }
  health_checks    = [google_compute_health_check.hc-int.id]
  session_affinity = "CLIENT_IP"
  protocol         = "TCP"
}

# Instance Group for Backend Pool
resource "google_compute_instance_group" "f5vm" {
  name = "${var.prefix}-ig"
  instances = [
    google_compute_instance.f5vm01.self_link,
    google_compute_instance.f5vm02.self_link
  ]
}

# Health Check for Backend Pool Internal
resource "google_compute_health_check" "hc-int" {
  name = "${var.prefix}-hc-int"
  tcp_health_check {
    port = "40000"
  }
}
