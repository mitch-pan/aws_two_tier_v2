data "aws_ami" "pa-vm" {
  most_recent = true
  owners      = ["aws-marketplace"]
  filter {
    name   = "product-code"
    values = [var.fw_license_type_map[var.fw_license_type]]
  }

  filter {
    name   = "name"
    values = ["PA-VM-AWS-${var.fw_version}*"]
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["aws-marketplace"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*${var.ubuntu_version}-amd64*"]
  }
}

data "aws_region" "current" {}