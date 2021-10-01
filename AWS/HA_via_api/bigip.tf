# BIG-IP Cluster

############################ Locals ############################

locals {
  # Retrieve all BIG-IP secondary IPs
  vm01_ext_ips = {
    0 = {
      ip = sort(aws_network_interface.vm01-ext-nic.private_ips)[0]
    }
    1 = {
      ip = sort(aws_network_interface.vm01-ext-nic.private_ips)[1]
    }
  }
  vm02_ext_ips = {
    0 = {
      ip = sort(aws_network_interface.vm02-ext-nic.private_ips)[0]
    }
    1 = {
      ip = sort(aws_network_interface.vm02-ext-nic.private_ips)[1]
    }
  }
  # Determine BIG-IP secondary IPs to be used for VIP
  vm01_vip_ips = {
    app1 = {
      ip = aws_network_interface.vm01-ext-nic.private_ip != local.vm01_ext_ips.0.ip ? local.vm01_ext_ips.0.ip : local.vm01_ext_ips.1.ip
    }
  }
  vm02_vip_ips = {
    app1 = {
      ip = aws_network_interface.vm02-ext-nic.private_ip != local.vm02_ext_ips.0.ip ? local.vm02_ext_ips.0.ip : local.vm02_ext_ips.1.ip
    }
  }
}

############################ AMI ############################

# Find BIG-IP AMI
data "aws_ami" "f5_ami" {
  most_recent = true
  owners      = ["aws-marketplace"]
  filter {
    name   = "name"
    values = [var.f5_ami_search_name]
  }
}

############################ SSH Key pair ############################

# Create SSH Key Pair
resource "aws_key_pair" "bigip" {
  key_name   = format("%s-key-%s", var.projectPrefix, random_id.buildSuffix.hex)
  public_key = var.ssh_key
}

############################ NICs ############################

# Create NIC for Management
resource "aws_network_interface" "vm01-mgmt-nic" {
  subnet_id       = var.mgmtSubnetAz1
  security_groups = [var.mgmtNsg]
  tags = {
    Name  = format("%s-vm01-mgmt-%s", var.projectPrefix, random_id.buildSuffix.hex)
    Owner = var.resourceOwner
  }
}

resource "aws_network_interface" "vm02-mgmt-nic" {
  subnet_id       = var.mgmtSubnetAz2
  security_groups = [var.mgmtNsg]
  tags = {
    Name  = format("%s-vm02-mgmt-%s", var.projectPrefix, random_id.buildSuffix.hex)
    Owner = var.resourceOwner
  }
}

# Create NIC for External
resource "aws_network_interface" "vm01-ext-nic" {
  subnet_id         = var.extSubnetAz1
  security_groups   = [var.extNsg]
  private_ips_count = 1
  source_dest_check = false
  tags = {
    Name                      = format("%s-vm01-ext-%s", var.projectPrefix, random_id.buildSuffix.hex)
    Owner                     = var.resourceOwner
    f5_cloud_failover_label   = format("%s-%s", var.projectPrefix, random_id.buildSuffix.hex)
    f5_cloud_failover_nic_map = "external"
  }
}

resource "aws_network_interface" "vm02-ext-nic" {
  subnet_id         = var.extSubnetAz2
  security_groups   = [var.extNsg]
  private_ips_count = 1
  source_dest_check = false
  tags = {
    Name                      = format("%s-vm02-ext-%s", var.projectPrefix, random_id.buildSuffix.hex)
    Owner                     = var.resourceOwner
    f5_cloud_failover_label   = format("%s-%s", var.projectPrefix, random_id.buildSuffix.hex)
    f5_cloud_failover_nic_map = "external"
  }
}

# Create NIC for Internal
resource "aws_network_interface" "vm01-int-nic" {
  subnet_id         = var.intSubnetAz1
  security_groups   = [var.intNsg]
  source_dest_check = false
  tags = {
    Name                      = format("%s-vm01-int-%s", var.projectPrefix, random_id.buildSuffix.hex)
    Owner                     = var.resourceOwner
    f5_cloud_failover_label   = format("%s-%s", var.projectPrefix, random_id.buildSuffix.hex)
    f5_cloud_failover_nic_map = "internal"
  }
}

resource "aws_network_interface" "vm02-int-nic" {
  subnet_id         = var.intSubnetAz2
  security_groups   = [var.intNsg]
  source_dest_check = false
  tags = {
    Name                      = format("%s-vm02-int-%s", var.projectPrefix, random_id.buildSuffix.hex)
    Owner                     = var.resourceOwner
    f5_cloud_failover_label   = format("%s-%s", var.projectPrefix, random_id.buildSuffix.hex)
    f5_cloud_failover_nic_map = "internal"
  }
}

############################ EIPs ############################

# Create Public IPs - mgmt
resource "aws_eip" "vm01-mgmt-pip" {
  vpc               = true
  network_interface = aws_network_interface.vm01-mgmt-nic.id
  tags = {
    Name  = format("%s-vm01-mgmt-pip-%s", var.projectPrefix, random_id.buildSuffix.hex)
    Owner = var.resourceOwner
  }
  depends_on = [aws_network_interface.vm01-mgmt-nic]
}

resource "aws_eip" "vm02-mgmt-pip" {
  vpc               = true
  network_interface = aws_network_interface.vm02-mgmt-nic.id
  tags = {
    Name  = format("%s-vm02-mgmt-pip-%s", var.projectPrefix, random_id.buildSuffix.hex)
    Owner = var.resourceOwner
  }
  depends_on = [aws_network_interface.vm02-mgmt-nic]
}

# Create Public IPs - external
resource "aws_eip" "vm01-ext-pip" {
  vpc                       = true
  network_interface         = aws_network_interface.vm01-ext-nic.id
  associate_with_private_ip = aws_network_interface.vm01-ext-nic.private_ip
  tags = {
    Name  = format("%s-vm01-ext-pip-%s", var.projectPrefix, random_id.buildSuffix.hex)
    Owner = var.resourceOwner
  }
  depends_on = [aws_network_interface.vm01-ext-nic]
}

resource "aws_eip" "vm02-ext-pip" {
  vpc                       = true
  network_interface         = aws_network_interface.vm02-ext-nic.id
  associate_with_private_ip = aws_network_interface.vm02-ext-nic.private_ip
  tags = {
    Name  = format("%s-vm02-ext-pip-%s", var.projectPrefix, random_id.buildSuffix.hex)
    Owner = var.resourceOwner
  }
  depends_on = [aws_network_interface.vm02-ext-nic]
}

# Create Public IPs - VIP
resource "aws_eip" "vip-pip" {
  vpc                       = true
  network_interface         = aws_network_interface.vm01-ext-nic.id
  associate_with_private_ip = local.vm01_vip_ips.app1.ip
  tags = {
    Name                    = format("%s-vip-pip-%s", var.projectPrefix, random_id.buildSuffix.hex)
    Owner                   = var.resourceOwner
    f5_cloud_failover_label = format("%s-%s", var.projectPrefix, random_id.buildSuffix.hex)
    f5_cloud_failover_vips  = "${local.vm01_vip_ips.app1.ip},${local.vm02_vip_ips.app1.ip}"
  }
  depends_on = [aws_network_interface.vm01-ext-nic]
}

############################ Onboard Scripts ############################

# Setup Onboarding scripts
locals {
  f5_onboard1 = templatefile("${path.module}/f5_onboard.tmpl", {
    regKey                  = var.license1
    f5_username             = var.f5_username
    f5_password             = var.f5_password
    ssh_keypair             = var.ssh_key
    INIT_URL                = var.INIT_URL
    DO_URL                  = var.DO_URL
    AS3_URL                 = var.AS3_URL
    TS_URL                  = var.TS_URL
    CFE_URL                 = var.CFE_URL
    FAST_URL                = var.FAST_URL
    DO_VER                  = split("/", var.DO_URL)[7]
    AS3_VER                 = split("/", var.AS3_URL)[7]
    TS_VER                  = split("/", var.TS_URL)[7]
    CFE_VER                 = split("/", var.CFE_URL)[7]
    FAST_VER                = split("/", var.FAST_URL)[7]
    vpc_cidr_block          = data.aws_vpc.main.cidr_block
    self_ip_external        = aws_network_interface.vm01-ext-nic.private_ip
    self_ip_internal        = aws_network_interface.vm01-int-nic.private_ip
    remote_selfip_ext       = aws_network_interface.vm02-ext-nic.private_ip
    vip_az1                 = local.vm01_vip_ips.app1.ip
    vip_az2                 = local.vm02_vip_ips.app1.ip
    dns_server              = var.dns_server
    ntp_server              = var.ntp_server
    timezone                = var.timezone
    host1                   = aws_network_interface.vm01-mgmt-nic.private_dns_name
    host2                   = aws_network_interface.vm02-mgmt-nic.private_dns_name
    remote_host             = aws_network_interface.vm02-int-nic.private_ip
    f5_cloud_failover_label = format("%s-%s", var.projectPrefix, random_id.buildSuffix.hex)
    cfe_managed_route       = var.cfe_managed_route
    bigIqLicenseType        = var.bigIqLicenseType
    bigIqHost               = var.bigIqHost
    bigIqPassword           = var.bigIqPassword
    bigIqUsername           = var.bigIqUsername
    bigIqLicensePool        = var.bigIqLicensePool
    bigIqSkuKeyword1        = var.bigIqSkuKeyword1
    bigIqSkuKeyword2        = var.bigIqSkuKeyword2
    bigIqUnitOfMeasure      = var.bigIqUnitOfMeasure
    bigIqHypervisor         = var.bigIqHypervisor
  })
  f5_onboard2 = templatefile("${path.module}/f5_onboard.tmpl", {
    regKey                  = var.license2
    f5_username             = var.f5_username
    f5_password             = var.f5_password
    ssh_keypair             = var.ssh_key
    INIT_URL                = var.INIT_URL
    DO_URL                  = var.DO_URL
    AS3_URL                 = var.AS3_URL
    TS_URL                  = var.TS_URL
    CFE_URL                 = var.CFE_URL
    FAST_URL                = var.FAST_URL
    DO_VER                  = split("/", var.DO_URL)[7]
    AS3_VER                 = split("/", var.AS3_URL)[7]
    TS_VER                  = split("/", var.TS_URL)[7]
    CFE_VER                 = split("/", var.CFE_URL)[7]
    FAST_VER                = split("/", var.FAST_URL)[7]
    vpc_cidr_block          = data.aws_vpc.main.cidr_block
    self_ip_external        = aws_network_interface.vm02-ext-nic.private_ip
    self_ip_internal        = aws_network_interface.vm02-int-nic.private_ip
    remote_selfip_ext       = aws_network_interface.vm01-ext-nic.private_ip
    vip_az1                 = local.vm01_vip_ips.app1.ip
    vip_az2                 = local.vm02_vip_ips.app1.ip
    dns_server              = var.dns_server
    ntp_server              = var.ntp_server
    timezone                = var.timezone
    host1                   = aws_network_interface.vm01-mgmt-nic.private_dns_name
    host2                   = aws_network_interface.vm02-mgmt-nic.private_dns_name
    remote_host             = aws_network_interface.vm01-int-nic.private_ip
    f5_cloud_failover_label = format("%s-%s", var.projectPrefix, random_id.buildSuffix.hex)
    cfe_managed_route       = var.cfe_managed_route
    bigIqLicenseType        = var.bigIqLicenseType
    bigIqHost               = var.bigIqHost
    bigIqPassword           = var.bigIqPassword
    bigIqUsername           = var.bigIqUsername
    bigIqLicensePool        = var.bigIqLicensePool
    bigIqSkuKeyword1        = var.bigIqSkuKeyword1
    bigIqSkuKeyword2        = var.bigIqSkuKeyword2
    bigIqUnitOfMeasure      = var.bigIqUnitOfMeasure
    bigIqHypervisor         = var.bigIqHypervisor
  })
}

############################ Compute ############################

# Create F5 BIG-IP VMs
resource "aws_instance" "f5vm01" {
  ami                  = data.aws_ami.f5_ami.id
  instance_type        = var.ec2_instance_type
  key_name             = aws_key_pair.bigip.key_name
  user_data            = base64encode(local.f5_onboard1)
  iam_instance_profile = aws_iam_instance_profile.bigip_profile.name

  network_interface {
    network_interface_id = aws_network_interface.vm01-mgmt-nic.id
    device_index         = 0
  }
  network_interface {
    network_interface_id = aws_network_interface.vm01-ext-nic.id
    device_index         = 1
  }
  network_interface {
    network_interface_id = aws_network_interface.vm01-int-nic.id
    device_index         = 2
  }

  root_block_device {
    delete_on_termination = true
  }

  tags = {
    Name  = format("%s-f5vm01-%s", var.projectPrefix, random_id.buildSuffix.hex)
    Owner = var.resourceOwner
  }
}

resource "aws_instance" "f5vm02" {
  ami                  = data.aws_ami.f5_ami.id
  instance_type        = var.ec2_instance_type
  key_name             = aws_key_pair.bigip.key_name
  user_data            = base64encode(local.f5_onboard2)
  iam_instance_profile = aws_iam_instance_profile.bigip_profile.name

  network_interface {
    network_interface_id = aws_network_interface.vm02-mgmt-nic.id
    device_index         = 0
  }
  network_interface {
    network_interface_id = aws_network_interface.vm02-ext-nic.id
    device_index         = 1
  }
  network_interface {
    network_interface_id = aws_network_interface.vm02-int-nic.id
    device_index         = 2
  }

  root_block_device {
    delete_on_termination = true
  }

  tags = {
    Name  = format("%s-f5vm02-%s", var.projectPrefix, random_id.buildSuffix.hex)
    Owner = var.resourceOwner
  }
}

############################ Route Table ############################

# Create Route Table
resource "aws_route_table" "main" {
  vpc_id = var.vpcId

  route {
    cidr_block           = var.cfe_managed_route
    network_interface_id = aws_network_interface.vm01-ext-nic.id
  }

  tags = {
    Name                    = format("%s-rt-%s", var.projectPrefix, random_id.buildSuffix.hex)
    Owner                   = var.resourceOwner
    f5_cloud_failover_label = format("%s-%s", var.projectPrefix, random_id.buildSuffix.hex)
    f5_self_ips             = "${aws_network_interface.vm01-ext-nic.private_ip},${aws_network_interface.vm02-ext-nic.private_ip}"
  }
}
