###############################################################
#   This section refers to the global variable declaration    #
#                                                             #
###############################################################

variable "environment" {
  type = string
}

variable "project" {
  type = string
}

variable "wp_version" {
  type    = string
  default = "MODIFY_ME"
}
variable "aws_region" {
  type    = string
  default = "MODIFY_ME"
}

variable "availability_zone_1" {
  type    = string
  default = "MODIFY_ME"
}

variable "availability_zone_2" {
  type    = string
  default = "MODIFY_ME"
}

variable "availability_zone_3" {
  type    = string
  default = "MODIFY_ME"
}

variable "aws_account_id" {
  type    = string
  default = "MODIFY_ME"
}

variable "aws_profile" {
  type    = string
  default = "Modify_ME"
}

variable "ami_id_bh" {
  type = string
}

variable "ami_id_ec2" {
  type = string
}

variable "ec2_type" {
  type = string
}

variable "bh_ec2_type" {
  type = string
}

variable "volume_size" {
  type = number
}

variable "bh_volume_size" {
  type = number
}

variable "vpc_id" {
  type    = string
  default = "MODIFY_ME"
}

variable "cidr_all" {
  type    = string
  default = "0.0.0.0/0"
}

variable "cidr_vpc" {
  type = string
}

variable "private_subnets" {
  type = list(string)
}

variable "public_subnets" {
  type = list(string)
}

variable "database_subnets" {
  type = list(string)
}

variable "general_tags" {

}

variable "agency_ips" {
  type = list(any)
}

variable "rds_engine" {
  type = string
}

variable "rds_engine_version" {
  type = string
}

variable "rds_instance_class" {
  type = string
}

variable "rds_storage_type" {
  type = string
}

variable "rds_username" {
  type = string
}

variable "rds_allocated_storage" {
  type = string
}

variable "rds_port" {
  type = string
}

variable "cloudfront_aliases" {
  type = list(string)
}

