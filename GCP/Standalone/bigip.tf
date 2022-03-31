# BIG-IP

# Public IP for VIP
resource "google_compute_address" "vip1" {
  name = format("%s-vip1-%s", var.projectPrefix, random_id.buildSuffix.hex)
}

# Forwarding rule for Public IP
resource "google_compute_forwarding_rule" "vip1" {
  name       = format("%s-forwarding-rule-%s", var.projectPrefix, random_id.buildSuffix.hex)
  target     = google_compute_target_instance.f5vm01.id
  ip_address = google_compute_address.vip1.address
  port_range = "1-65535"
}

resource "google_compute_target_instance" "f5vm01" {
  name     = format("%s-ti-%s", var.projectPrefix, random_id.buildSuffix.hex)
  instance = google_compute_instance.f5vm01.id
  zone     = var.gcp_zone_1
}

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
    regKey             = var.license1
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
    #publicvip  = "0.0.0.0"
    publicvip  = google_compute_address.vip1.address
    privatevip = var.alias_ip_range
  })
  ts_json = templatefile("${path.module}/ts.json", {
    gcp_project_id = var.gcp_project_id
    svc_acct       = var.svc_acct
    privateKeyId   = var.privateKeyId
  })
}

# Create F5 BIG-IP VMs
resource "google_compute_instance" "f5vm01" {
  name           = format("%s-f5vm01-%s", var.projectPrefix, random_id.buildSuffix.hex)
  machine_type   = var.bigipMachineType
  zone           = var.gcp_zone_1
  can_ip_forward = true

  tags = ["appfw-${var.projectPrefix}", "mgmtfw-${var.projectPrefix}"]

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
    alias_ip_range {
      ip_cidr_range = var.alias_ip_range
    }
  }

  network_interface {
    network    = var.mgmtVpc
    subnetwork = var.mgmtSubnet
    access_config {
    }
  }

  network_interface {
    network    = var.intVpc
    subnetwork = var.intSubnet
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
