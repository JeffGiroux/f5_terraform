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
    CF_URL         = var.CF_URL
    onboard_log    = var.onboard_log
    DO_Document    = local.vm01_do_json
    AS3_Document   = ""
    TS_Document    = local.ts_json
    CFE_Document   = local.vm01_cfe_json
  })
  vm02_onboard = templatefile("${path.module}/onboard.tpl", {
    uname          = var.uname
    usecret        = var.usecret
    ksecret        = var.ksecret
    gcp_project_id = var.gcp_project_id
    DO_URL         = var.DO_URL
    AS3_URL        = var.AS3_URL
    TS_URL         = var.TS_URL
    CF_URL         = var.CF_URL
    onboard_log    = var.onboard_log
    DO_Document    = local.vm02_do_json
    AS3_Document   = local.as3_json
    TS_Document    = local.ts_json
    CFE_Document   = local.vm02_cfe_json
  })
  vm01_do_json = templatefile("${path.module}/do.json", {
    regKey             = var.license1
    admin_username     = var.uname
    local_host         = "${var.prefix}-${var.host1_name}"
    dns_server         = var.dns_server
    dns_suffix         = var.dns_suffix
    ntp_server         = var.ntp_server
    timezone           = var.timezone
    host1              = "${var.prefix}-${var.host1_name}"
    host2              = "${var.prefix}-${var.host2_name}"
    remote_host        = "${var.prefix}-${var.host2_name}"
    bigIqLicenseType   = var.bigIqLicenseType
    bigIqHost          = var.bigIqHost
    bigIqUsername      = var.bigIqUsername
    bigIqLicensePool   = var.bigIqLicensePool
    bigIqSkuKeyword1   = var.bigIqSkuKeyword1
    bigIqSkuKeyword2   = var.bigIqSkuKeyword2
    bigIqUnitOfMeasure = var.bigIqUnitOfMeasure
    bigIqHypervisor    = var.bigIqHypervisor
  })
  vm02_do_json = templatefile("${path.module}/do.json", {
    regKey             = var.license2
    host1              = "${var.prefix}-${var.host1_name}"
    host2              = "${var.prefix}-${var.host2_name}"
    local_host         = "${var.prefix}-${var.host2_name}"
    remote_host        = "${var.prefix}-${var.host1_name}"
    dns_server         = var.dns_server
    dns_suffix         = var.dns_suffix
    ntp_server         = var.ntp_server
    timezone           = var.timezone
    admin_username     = var.uname
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
    #privatevip = google_compute_forwarding_rule.vip2-internal.ip_address
    privatevip = data.google_compute_subnetwork.vpc_ext_sub.ip_cidr_range
  })
  ts_json = templatefile("${path.module}/ts.json", {
    gcp_project_id = var.gcp_project_id
    svc_acct       = var.svc_acct
    privateKeyId   = var.privateKeyId
  })
  vm01_cfe_json = templatefile("${path.module}/cfe.json", {
    f5_cloud_failover_label = var.f5_cloud_failover_label
    managed_route1          = var.managed_route1
    remote_selfip           = ""
  })
  vm02_cfe_json = templatefile("${path.module}/cfe.json", {
    f5_cloud_failover_label = var.f5_cloud_failover_label
    managed_route1          = var.managed_route1
    remote_selfip           = google_compute_instance.f5vm01.network_interface.0.network_ip
  })
}

# Create F5 BIG-IP VMs
resource "google_compute_instance" "f5vm01" {
  name           = "${var.prefix}-${var.host1_name}"
  machine_type   = var.bigipMachineType
  zone           = var.gcp_zone
  can_ip_forward = true

  labels = {
    f5_cloud_failover_label = var.f5_cloud_failover_label
  }

  tags = ["appfw-${var.prefix}", "mgmtfw-${var.prefix}"]

  boot_disk {
    initialize_params {
      image = var.customImage != "" ? var.customImage : var.image_name
      size  = "128"
    }
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
}

resource "google_compute_instance" "f5vm02" {
  name           = "${var.prefix}-${var.host2_name}"
  machine_type   = var.bigipMachineType
  zone           = var.gcp_zone
  can_ip_forward = true

  labels = {
    f5_cloud_failover_label = var.f5_cloud_failover_label
  }

  tags = ["appfw-${var.prefix}", "mgmtfw-${var.prefix}"]

  boot_disk {
    initialize_params {
      image = var.customImage != "" ? var.customImage : var.image_name
      size  = "128"
    }
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
    startup-script         = var.customImage != "" ? var.customUserData : local.vm02_onboard
  }

  service_account {
    email  = var.svc_acct
    scopes = ["cloud-platform"]
  }
}

# # Troubleshooting - create local output files
# resource "local_file" "onboard_file" {
#   content  = local.vm01_onboard
#   filename = "${path.module}/vm01_onboard.tpl_data.json"
# }
