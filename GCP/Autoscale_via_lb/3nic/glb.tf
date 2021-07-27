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
  health_checks = [
    google_compute_http_health_check.hc-ext.name,
  ]
  session_affinity = "CLIENT_IP"
}

# Health Check for Backend Pool External
resource "google_compute_http_health_check" "hc-ext" {
  name                = "${var.prefix}-hc-ext"
  port                = "40000"
  timeout_sec         = 2
  check_interval_sec  = 5
  healthy_threshold   = 2
  unhealthy_threshold = 2
}
