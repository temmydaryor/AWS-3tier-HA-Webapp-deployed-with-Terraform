variable "project_name" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "azs" {
  type = list(string)
}

variable "public_subnet_cidrs" {
  type = list(string)
}

variable "private_subnet_cidrs" {
  type = list(string)
}

variable "single_nat_gateway" {
  description = "If true, create only 1 NAT Gateway (cheaper). If false, 1 per AZ (more HA)."
  type        = bool
  default     = true
}
