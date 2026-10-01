variable "project_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "admin_cidr" {
  description = "Your IP in CIDR form, e.g. 203.0.113.5/32, for SSH access"
  type        = string
}

variable "private_subnet_ids" {
  description = "Used to place the EC2 Instance Connect Endpoint"
  type        = list(string)
}
