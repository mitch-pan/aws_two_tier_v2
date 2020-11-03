/*
  Create the VPC
*/
resource "aws_vpc" "main" {
  cidr_block = var.VPCCIDR
  tags = {
    "Application" = var.StackName
    "Network"     = "MGMT"
    "Name"        = var.VPCName
  }
}
resource "aws_vpc_dhcp_options" "dopt21c7d043" {
  domain_name         = "${data.aws_region.current.name}.compute.internal"
  domain_name_servers = ["AmazonProvidedDNS"]
}

resource "aws_subnet" "NewPublicSubnet" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.PublicCIDR_Block
  availability_zone = data.aws_availability_zones.available.names[0]
  tags = {
    "Application" = var.StackName
    "Name"        = join("", [var.StackName, "NewPublicSubnet"])
  }
}

resource "aws_subnet" "NewWebSubnet" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.WebCIDR_Block
  availability_zone = data.aws_availability_zones.available.names[0]

  #map_public_ip_on_launch = true
  tags = {
    "Application" = var.StackName
    "Name"        = join("", [var.StackName, "NewWebSubnet"])
  }
}
resource "aws_network_acl" "aclb765d6d2" {
  vpc_id = aws_vpc.main.id
  subnet_ids = [
    aws_subnet.NewPublicSubnet.id,
    aws_subnet.NewWebSubnet.id,
  ]
}

resource "aws_network_acl_rule" "acl1" {
  network_acl_id = aws_network_acl.aclb765d6d2.id
  rule_number    = 100
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
}

resource "aws_network_acl_rule" "acl2" {
  network_acl_id = aws_network_acl.aclb765d6d2.id
  rule_number    = 100
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
}

resource "aws_route_table" "rtb-internetgw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "rtb-ngfw" {
  vpc_id = aws_vpc.main.id

  route {
        cidr_block = "0.0.0.0/0"
        network_interface_id = "${aws_network_interface.FWPrivate12NetworkInterface.id}"
    }
}

resource "aws_internet_gateway" "InternetGateway" {
  vpc_id = aws_vpc.main.id
  tags = {
    Application = var.StackName
    Network     = "MGMT"
    Name        = join("-", [var.StackName, "InternetGateway"])
  }
}

resource "aws_route_table_association" "subnet-route-through-igw" {
  subnet_id      = aws_subnet.NewPublicSubnet.id
  route_table_id = aws_route_table.rtb-internetgw.id
}

resource "aws_route_table_association" "subnet-route-through-ngfw" {
  subnet_id      = aws_subnet.NewWebSubnet.id
  route_table_id = aws_route_table.rtb-ngfw.id
}


resource "aws_route" "route-through-igw" {
  route_table_id         = aws_route_table.rtb-internetgw.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.InternetGateway.id
}
