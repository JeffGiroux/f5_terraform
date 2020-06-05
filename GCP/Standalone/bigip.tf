# BIG-IP

# Generate Random Password
resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = " #%*+,-./:=?@[]^_~"
}

# Setup Onboarding scripts
data "template_file" "vm_onboard" {
  template = file("${path.module}/onboard.sh")

  vars = {
    uname         = var.adminAccountName
    upassword     = var.adminPass != "" ? "${var.adminPass}" : "${random_password.password.result}"
    doVersion     = "latest"
    as3Version    = "latest"
    tsVersion     = "latest"
    cfVersion     = "latest"
    fastVersion   = "latest"
    libs_dir      = var.libsDir
    onboard_log   = var.onboardLog
    projectPrefix = var.projectPrefix
    buildSuffix   = "-${random_pet.buildSuffix.id}"
  }
}

# Create F5 BIG-IP VMs
resource "google_compute_instance" "vm_instance" {
  count        = var.instanceCount
  name         = "${var.projectPrefix}${var.name}-${count.index + 1}-instance-${random_pet.buildSuffix.id}"
  machine_type = var.bigipMachineType
  tags         = ["allow-health-checks"]
  boot_disk {
    initialize_params {
      image = var.customImage != "" ? "${var.customImage}" : "${var.bigipImage}"
      size  = "128"
    }
  }
  metadata = {
    ssh-keys               = "${var.adminAccountName}:${var.gceSshPubKey}"
    block-project-ssh-keys = true
    # this is best for a long running instance as it is only evaulated and run once, changes to the template do NOT destroy the running instance.
    startup-script = var.customImage != "" ? "${var.customUserData}" : "${data.template_file.vm_onboard.rendered}"
    deviceId       = "${count.index + 1}"
  }
  # this is best for dev, as it runs ANY time there are changes and DESTROYS the instances
  #metadata_startup_script = var.customImage != "" ? "${var.customUserData}" : "${data.template_file.vm_onboard.rendered}"

  network_interface {
    # external
    network    = var.extVpc
    subnetwork = var.extSubnet
    access_config {
    }
  }
  network_interface {
    # mgmt
    network    = var.mgmtVpc
    subnetwork = var.mgmtSubnet
    access_config {
    }
  }
  service_account {
    # https://cloud.google.com/sdk/gcloud/reference/alpha/compute/instances/set-scopes#--scopes
    # email = var.service_accounts.compute
    scopes = ["storage-ro", "logging-write", "monitoring-write", "monitoring", "pubsub", "service-management", "service-control"]
  }
}
