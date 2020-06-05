# provider
provider "google" {

  project = var.GCP_PROJECT_ID
  region  = var.GCP_REGION
  zone    = var.GCP_ZONE

}

# project
resource "random_pet" "buildSuffix" {
  keepers = {
    # Generate a new pet name each time we switch to a new AMI id
    #ami_id = var.ami_id}"
    prefix = var.projectPrefix
  }
  #length = ""
  #prefix = var.projectPrefix}"
  separator = "-"
}
# password
resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = " #%*+,-./:=?@[]^_~"
}

module "bigip" {
  source = "../../terraform-gcp-bigip/"
  #source = "github.com/jeffgiroux/terraform-gcp-bigip?ref=master"
  #====================#
  # BIG-IP settings    #
  #====================#
  gceSshPubKey     = var.gceSshPubKey
  projectPrefix    = var.projectPrefix
  buildSuffix      = "-${random_pet.buildSuffix.id}"
  adminSrcAddr     = var.adminSrcAddr
  adminPass        = "${random_password.password.result}"
  adminAccountName = var.adminAccountName
  mgmtVpc          = var.mgmtVpc
  intVpc           = var.intVpc
  extVpc           = var.extVpc
  mgmtSubnet       = var.mgmtSubnet
  intSubnet        = var.intSubnet
  extSubnet        = var.extSubnet
  serviceAccounts  = var.serviceAccounts
  instanceCount    = 1
  customImage      = ""
  customUserData   = ""
  bigipMachineType = "n1-standard-8"
}