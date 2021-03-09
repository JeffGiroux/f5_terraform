# Networking

# Create VPC, subnets, route tables, and IGW
module "aws_network" {
  source                  = "github.com/f5devcentral/f5-digital-customer-engagement-center//modules/aws/terraform/network/min?ref=v1.1.0"
  projectPrefix           = var.projectPrefix
  buildSuffix             = random_id.buildSuffix.hex
  resourceOwner           = var.resourceOwner
  map_public_ip_on_launch = true
}
