# Main

# Google Provider
provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

# Create a random id
resource "random_id" "buildSuffix" {
  byte_length = 2
}
