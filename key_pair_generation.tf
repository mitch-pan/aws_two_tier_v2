resource "tls_private_key" "this" {
  algorithm = "RSA"
}

module "key_pair" {
  source          = "terraform-aws-modules/key-pair/aws"
  create_key_pair = true
  key_name        = var.new_servicekey
  public_key      = tls_private_key.this.public_key_openssh
}

output "my_private_key" {
  value = tls_private_key.this.private_key_pem
}

resource "local_file" "private_key" {
  filename = var.private_key_path
  content  = tls_private_key.this.private_key_pem
}