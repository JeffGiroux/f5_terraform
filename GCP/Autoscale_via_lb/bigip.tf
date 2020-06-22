# BIG-IP

# Setup Onboarding scripts
locals {
  vm01_onboard = templatefile("${path.module}/onboard.tpl", {
    uname          = var.uname
    usecret        = var.usecret
    ksecret        = var.ksecret
    gcp_project_id = var.gcp_project_id
    DO_URL         = var.DO_URL
    AS3_URL        = var.AS3_URL
    TS_URL         = var.TS_URL
    onboard_log    = var.onboard_log
    DO_Document    = local.vm01_do_json
    AS3_Document   = local.as3_json
    TS_Document    = local.ts_json
  })
  vm01_do_json = templatefile("${path.module}/do.json", {
    admin_username     = var.uname
    dns_server         = var.dns_server
    dns_suffix         = var.dns_suffix
    ntp_server         = var.ntp_server
    timezone           = var.timezone
    bigIqLicenseType   = var.bigIqLicenseType
    bigIqHost          = var.bigIqHost
    bigIqUsername      = var.bigIqUsername
    bigIqLicensePool   = var.bigIqLicensePool
    bigIqSkuKeyword1   = var.bigIqSkuKeyword1
    bigIqSkuKeyword2   = var.bigIqSkuKeyword2
    bigIqUnitOfMeasure = var.bigIqUnitOfMeasure
    bigIqHypervisor    = var.bigIqHypervisor
  })
  as3_json = templatefile("${path.module}/as3.json", {
    gcp_region = var.gcp_region
    publicvip  = google_compute_address.vip1.address
    #publicvip = "0.0.0.0/0"
  })
  ts_json = templatefile("${path.module}/ts.json", {
    gcp_project_id = var.gcp_project_id
    svc_acct       = var.svc_acct
    privateKeyId   = var.privateKeyId
  })
}

# F5 BIG-IP VMs Instance Template
resource "google_compute_instance_template" "f5vm" {
  name_prefix    = "${var.prefix}-f5vm-"
  machine_type   = var.bigipMachineType
  can_ip_forward = true

  tags = ["appfw-${var.prefix}", "mgmtfw-${var.prefix}"]

  disk {
    source_image = var.customImage != "" ? var.customImage : var.image_name
  }

  network_interface {
    network    = var.extVpc
    subnetwork = var.extSubnet
    access_config {
    }
  }

  network_interface {
    network    = var.mgmtVpc
    subnetwork = var.mgmtSubnet
    access_config {
    }
  }

  metadata = {
    ssh-keys               = "${var.uname}:${var.gceSshPubKey}"
    block-project-ssh-keys = true
    startup-script         = var.customImage != "" ? var.customUserData : local.vm01_onboard
  }

  service_account {
    email  = var.svc_acct
    scopes = ["cloud-platform"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Health Check for BIG-IP instance group for auto healing
resource "google_compute_health_check" "f5vm" {
  name                = "${var.prefix}-hc-f5vm"
  timeout_sec         = 10
  check_interval_sec  = 30
  healthy_threshold   = 2
  unhealthy_threshold = 5

  tcp_health_check {
    port = 40000
  }
}

# Managed Instance Group (auto healing, upgrades)
resource "google_compute_region_instance_group_manager" "f5vm" {
  name               = "${var.prefix}-igm"
  base_instance_name = "${var.prefix}-f5vm"
  region             = var.gcp_region
  target_pools       = [google_compute_target_pool.f5vm.id]
  wait_for_instances = false

  version {
    name              = google_compute_instance_template.f5vm.name
    instance_template = google_compute_instance_template.f5vm.id
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.f5vm.self_link
    initial_delay_sec = var.auto_healing_initial_delay_sec
  }

  update_policy {
    type                  = var.update_policy_type
    minimal_action        = var.update_policy_minimal_action
    max_surge_fixed       = var.update_policy_max_surge_fixed
    max_unavailable_fixed = var.update_policy_max_unavailable_fixed
    min_ready_sec         = var.update_policy_min_ready_sec
  }
}

# Autoscaling policies
resource "google_compute_region_autoscaler" "f5vm" {
  name   = "${var.prefix}-f5vm-as"
  target = google_compute_region_instance_group_manager.f5vm.id

  autoscaling_policy {
    max_replicas    = var.autoscaling_max_replicas
    min_replicas    = var.autoscaling_min_replicas
    cooldown_period = var.autoscaling_cooldown_period

    cpu_utilization {
      target = var.autoscaling_cpu_target
    }
  }
}

# # Troubleshooting - create local output files
# resource "local_file" "onboard_file" {
#   content  = local.vm01_onboard
#   filename = "${path.module}/vm01_onboard.tpl_data.json"
# }
