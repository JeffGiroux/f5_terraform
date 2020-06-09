# BIG-IP

# Setup Onboarding scripts
data "template_file" "vm_onboard" {
  template = file("${path.module}/onboard.tpl")

  vars = {
    uname          = var.uname
    usecret        = var.usecret
    gcp_project_id = var.gcp_project_id
    DO_URL         = var.DO_URL
    AS3_URL        = var.AS3_URL
    TS_URL         = var.TS_URL
    onboard_log    = var.onboard_log
  }
}

# Create F5 BIG-IP VMs
resource "google_compute_instance" "f5vm01" {
  name         = "${var.prefix}-f5vm01"
  machine_type = var.bigipMachineType
  zone         = var.gcp_zone

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

  metadata = {
    ssh-keys               = "${var.uname}:${var.gceSshPubKey}"
    block-project-ssh-keys = true
    startup-script         = var.customImage != "" ? var.customUserData : data.template_file.vm_onboard.rendered
  }

  service_account {
    email  = var.svc_acct
    scopes = ["cloud-platform"]
  }
}

# Troubleshooting - create local output files
resource "local_file" "onboard_file" {
  content  = data.template_file.vm_onboard.rendered
  filename = "${path.module}/vm_onboard.tpl_data.json"
}
