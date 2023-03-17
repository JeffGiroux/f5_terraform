# BIG-IP

############################ Onboard Scripts ############################

# Setup Onboarding scripts
locals {
  f5_onboard1 = templatefile("${path.module}/f5_onboard.tmpl", {
    f5_username                       = var.f5_username
    f5_password                       = var.gcp_secret_manager_authentication ? "" : var.f5_password
    gcp_secret_manager_authentication = var.gcp_secret_manager_authentication
    gcp_secret_name                   = var.gcp_secret_manager_authentication ? var.gcp_secret_name : ""
    gcp_secret_version                = var.gcp_secret_manager_authentication ? var.gcp_secret_version : ""
    ssh_keypair                       = file(var.ssh_key)
    gcp_project_id                    = var.gcp_project_id
    INIT_URL                          = var.INIT_URL
    DO_URL                            = var.DO_URL
    AS3_URL                           = var.AS3_URL
    TS_URL                            = var.TS_URL
    FAST_URL                          = var.FAST_URL
    DO_VER                            = split("/", var.DO_URL)[7]
    AS3_VER                           = split("/", var.AS3_URL)[7]
    TS_VER                            = split("/", var.TS_URL)[7]
    FAST_VER                          = split("/", var.FAST_URL)[7]
    dns_server                        = var.dns_server
    dns_suffix                        = var.dns_suffix
    ntp_server                        = var.ntp_server
    timezone                          = var.timezone
    bigIqLicenseType                  = var.bigIqLicenseType
    bigIqHost                         = var.bigIqHost
    bigIqPassword                     = var.bigIqPassword
    bigIqUsername                     = var.bigIqUsername
    bigIqLicensePool                  = var.bigIqLicensePool
    bigIqSkuKeyword1                  = var.bigIqSkuKeyword1
    bigIqSkuKeyword2                  = var.bigIqSkuKeyword2
    bigIqUnitOfMeasure                = var.bigIqUnitOfMeasure
    bigIqHypervisor                   = var.bigIqHypervisor
    NIC_COUNT                         = false
    public_vip                        = google_compute_address.vip1.address
  })
}

############################ Compute ############################

# F5 BIG-IP VMs Instance Template
resource "google_compute_instance_template" "bigip" {
  name_prefix    = format("%s-bigip-%s", var.projectPrefix, random_id.buildSuffix.hex)
  machine_type   = var.machine_type
  can_ip_forward = true

  tags = ["appfw-${var.projectPrefix}", "mgmtfw-${var.projectPrefix}"]

  disk {
    source_image = var.customImage != "" ? var.customImage : var.image_name
  }

  network_interface {
    network    = var.extVpc
    subnetwork = var.extSubnet
    access_config {
    }
  }

  metadata = {
    ssh-keys               = "${var.f5_username}:${file(var.ssh_key)}"
    block-project-ssh-keys = true
    startup-script         = var.customImage != "" ? var.customUserData : local.f5_onboard1
  }

  service_account {
    email  = var.svc_acct
    scopes = ["cloud-platform"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

############################ Autoscaling ############################

# Health Check for BIG-IP instance group for auto healing
resource "google_compute_health_check" "bigip" {
  name                = format("%s-hc-bigip-%s", var.projectPrefix, random_id.buildSuffix.hex)
  timeout_sec         = 10
  check_interval_sec  = 30
  healthy_threshold   = 2
  unhealthy_threshold = 5

  tcp_health_check {
    port = 40000
  }
}

# Managed Instance Group (auto healing, upgrades)
resource "google_compute_region_instance_group_manager" "bigip" {
  name               = format("%s-igm-%s", var.projectPrefix, random_id.buildSuffix.hex)
  base_instance_name = var.vm_name == "" ? format("%s-bigip", var.projectPrefix) : var.vm_name
  region             = var.gcp_region
  target_pools       = [google_compute_target_pool.f5vm.id]
  wait_for_instances = false

  version {
    name              = google_compute_instance_template.bigip.name
    instance_template = google_compute_instance_template.bigip.id
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.bigip.self_link
    initial_delay_sec = var.auto_healing_initial_delay_sec
  }

  update_policy {
    type                  = var.update_policy_type
    minimal_action        = var.update_policy_minimal_action
    max_surge_fixed       = var.update_policy_max_surge_fixed
    max_unavailable_fixed = var.update_policy_max_unavailable_fixed
    #min_ready_sec         = var.update_policy_min_ready_sec
  }
}

# Autoscaling policies
resource "google_compute_region_autoscaler" "bigip" {
  name   = format("%s-bigip-as-%s", var.projectPrefix, random_id.buildSuffix.hex)
  target = google_compute_region_instance_group_manager.bigip.id

  autoscaling_policy {
    max_replicas    = var.autoscaling_max_replicas
    min_replicas    = var.autoscaling_min_replicas
    cooldown_period = var.autoscaling_cooldown_period

    cpu_utilization {
      target = var.autoscaling_cpu_target
    }
  }
}
