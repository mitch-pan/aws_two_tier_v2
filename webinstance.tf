resource "aws_network_interface" "WPNetworkInterface" {
  subnet_id         = aws_subnet.NewWebSubnet.id
  security_groups   = [aws_security_group.sgWideOpen.id]
  private_ips       = ["10.0.1.101"]
}

resource "aws_instance" "WPWebInstance" {
  disable_api_termination              = false
  instance_initiated_shutdown_behavior = "stop"
  ami                                  = data.aws_ami.ubuntu.id
  instance_type                        = "t2.micro"
  key_name   = module.key_pair.this_key_pair_key_name
  monitoring = false

  network_interface {
    //delete_on_termination = true
    device_index         = 0
    network_interface_id = aws_network_interface.WPNetworkInterface.id
  }


  //user_data = "${file("install.sh")}"

  user_data_base64 = base64encode(
    join(
      "",
      [
        "#! /bin/bash\n",
        "exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1\n",
        "echo \"export new_routers='${sort(aws_network_interface.FWPrivate12NetworkInterface.private_ips)[0]}'\" >> /etc/dhcp/dhclient-enter-hooks.d/aws-default-route\n",
        "ifdown eth0\n",
        "ifup eth0\n",
        "apt-get update\n",
        "apt-get install -y apache2\n",
        "echo \"<h1>Deployed via Terraform</h1>\" | sudo tee /var/www/html/index.html",
      ],
    ),
  )
}

 output "Ubuntu_SSH_Command" {
  value = join("", ["ssh -i ", var.private_key_path, " ubuntu@", aws_eip.PublicElasticIP.public_ip, " -p 221"] )
}
