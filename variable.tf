variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project_name" {
  type    = string
  default = "portfolio-app"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "azs" {
  type    = list(string)
  default = ["ca-west-1a", "ca-west-1b"]
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "single_nat_gateway" {
  description = "true = 1 NAT Gateway (cheaper, less HA). false = 1 per AZ."
  type        = bool
  default     = true
}

variable "admin_cidr" {
  description = "YOUR IP in CIDR form for SSH access, e.g. 203.0.113.5/32"
  type        = string
}

variable "key_name" {
  description = "Name of an existing EC2 key pair in this region"
  type        = string
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "db_username" {
  type    = string
  default = "admin"
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "asset_bucket_name" {
  description = "Must be globally unique, e.g. portfolio-app-assets-yourname"
  type        = string
}
