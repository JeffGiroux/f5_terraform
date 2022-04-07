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
  health_checks = [
    google_compute_http_health_check.hc-ext.name,
  ]
  session_affinity = "CLIENT_IP"
}

# Health Check for Backend Pool External
resource "google_compute_http_health_check" "hc-ext" {
  name                = format("%s-hc-ext-%s", var.projectPrefix, random_id.buildSuffix.hex)
  port                = "40000"
  timeout_sec         = 2
  check_interval_sec  = 5
  healthy_threshold   = 2
  unhealthy_threshold = 2
}
