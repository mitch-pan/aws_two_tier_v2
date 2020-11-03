resource "aws_iam_role" "FirewallBootstrapRole2Tier" {
  name = "FirewallBootstrapRole2Tier"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
      "Service": "ec2.amazonaws.com"
    },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

}

resource "aws_iam_role_policy" "FirewallBootstrapRolePolicy2Tier" {
  name = "FirewallBootstrapRolePolicy2Tier"
  role = aws_iam_role.FirewallBootstrapRole2Tier.id

  policy = <<EOF
{
  "Version" : "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:ListBucket",
      "Resource": "${aws_s3_bucket.bucket.arn}"
    },
    {
    "Effect": "Allow",
    "Action": "s3:GetObject",
    "Resource": "${aws_s3_bucket.bucket.arn}/*"
    }
  ]
}
EOF

}

resource "aws_iam_instance_profile" "FirewallBootstrapInstanceProfile2Tier" {
  name = "FirewallBootstrapInstanceProfile2Tier"
  role = aws_iam_role.FirewallBootstrapRole2Tier.name
  path = "/"
}

resource "aws_network_interface" "FWManagementNetworkInterface" {
  subnet_id         = aws_subnet.NewPublicSubnet.id
  security_groups   = [aws_security_group.sgWideOpen.id]
  source_dest_check = true
  private_ip       = "10.0.0.99"
}

resource "aws_network_interface" "FWPublicNetworkInterface" {
  subnet_id         = aws_subnet.NewPublicSubnet.id
  security_groups   = [aws_security_group.sgWideOpen.id]
  source_dest_check = false
  private_ips = ["10.0.0.100"]
}

resource "aws_network_interface" "FWPrivate12NetworkInterface" {
  subnet_id         = aws_subnet.NewWebSubnet.id
  security_groups   = [aws_security_group.sgWideOpen.id]
  source_dest_check = false
  private_ips = ["10.0.1.11"]
}

resource "aws_eip" "PublicElasticIP" {
  vpc = true
  depends_on = [
    aws_vpc.main,
    aws_internet_gateway.InternetGateway,
  ]
}

resource "aws_eip" "ManagementElasticIP" {
  vpc = true
  depends_on = [
    aws_vpc.main,
    aws_internet_gateway.InternetGateway,
  ]
}

resource "aws_eip_association" "FWEIPManagementAssociation" {
  network_interface_id = aws_network_interface.FWManagementNetworkInterface.id
  allocation_id        = aws_eip.ManagementElasticIP.id
}

resource "aws_eip_association" "FWEIPPublicAssociation" {
  network_interface_id = aws_network_interface.FWPublicNetworkInterface.id
  allocation_id        = aws_eip.PublicElasticIP.id
}

resource "aws_vpc_dhcp_options_association" "dchpassoc1" {
  vpc_id          = aws_vpc.main.id
  dhcp_options_id = aws_vpc_dhcp_options.dopt21c7d043.id
}

resource "aws_security_group" "sgWideOpen" {
  name        = "sgWideOpen"
  description = "Wide open security group"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "FWInstance" {
  disable_api_termination              = false
  iam_instance_profile                 = aws_iam_instance_profile.FirewallBootstrapInstanceProfile2Tier.name
  instance_initiated_shutdown_behavior = "stop"
  ebs_optimized                        = true
  ami                                  = data.aws_ami.pa-vm.id
  instance_type                        = var.fw_instance_size

  ebs_block_device {
    device_name           = "/dev/xvda"
    volume_type           = "gp2"
    //delete_on_termination = true
    volume_size           = 60
  }

  key_name   = module.key_pair.this_key_pair_key_name
  monitoring = false

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.FWManagementNetworkInterface.id
  }

  network_interface {
    device_index         = 1
    network_interface_id = aws_network_interface.FWPublicNetworkInterface.id
  }

  network_interface {
    device_index         = 2
    network_interface_id = aws_network_interface.FWPrivate12NetworkInterface.id
  }

  user_data = base64encode(
    join("", ["vmseries-bootstrap-aws-s3bucket=", aws_s3_bucket.bucket.id]),
  )
}

//resource "null_resource" "check_fw_ready" {
//  triggers = {
//    key = aws_instance.FWInstance.id
//  }
//
//  provisioner "local-exec" {
//    command = "./check_fw.sh ${aws_eip.ManagementElasticIP.public_ip}"
//  }
//}

output "FirewallManagementURL" {
  value = join("", ["https://", aws_eip.ManagementElasticIP.public_ip])
}

output "WebURL" {
  value = join("", ["http://", aws_eip.PublicElasticIP.public_ip])
}

output "FW_SSH_Command" {
  value = join("", ["ssh -i ", var.private_key_path, " admin@", aws_eip.ManagementElasticIP.public_ip])
}
