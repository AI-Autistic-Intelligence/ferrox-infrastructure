variable "aws_region" {
  type    = string
  default = "eu-central-1"
}

variable "db_username" {
  type    = string
  default = "ferrox_admin"
}

variable "db_password" {
  type      = string
  sensitive = true
}
