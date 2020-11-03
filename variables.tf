data "aws_availability_zones" "available" {
}

variable "aws_region" {
  default = "us-east-1"
}

variable "WebCIDR_Block" {
}

variable "PublicCIDR_Block" {
}

//variable "MasterS3Bucket" {
//}

variable "VPCName" {
}

variable "VPCCIDR" {
}

variable "new_servicekey" {
}

variable "StackName" {
}

variable "fw_instance_size" {
  default = "m5.xlarge"
}


variable "ubuntu_version" {
  description = "Ubuntu Version to Filter on"
  default     = "18.04"
}

# Firewall version for AMI lookup

variable "fw_version" {
  description = "Select which FW version to deploy"
  default     = "9.1.3"
  # Acceptable Values Below
}

# License type for AMI lookup
variable "fw_license_type" {
  description = "Select License type (byol/payg1/payg2)"
  default     = "byol"
}

# Product code map based on license type for ami filter

variable "fw_license_type_map" {
  type = map(string)
  default = {
    "byol"  = "6njl1pau431dv1qxipg63mvah"
    "payg1" = "e9yfvyj3uag5uo5j2hjikv74n"
    "payg2" = "hd44w1chf26uv4p52cdynb2o"
  }
}

variable "bootstrap_directories" {
  description = "The directories comprising the bootstrap package"
  type        = list(string)
  default = [
    "config/",
    "content/",
    "software/",
    "license/",
    "plugins/"
  ]
}

variable "bucket_prefix" {
  description = "Prefix of the bucket name"
  type        = string
  default     = "bootstrap-"
}

variable "local_directory" {
  description = "local folder to copy to s3"
  type        = string
  default     = "files"
}

variable "private_key_path" {
  default = "./private_key"
  type = string
}