#6/24/2019

variable "environment_tag" {
  description = "Tag to be added to all of the resources as an identifier"
  default     = ""
}
variable "network_address_space" {
  description = "The CIDR block for the VPC"
  default     = ""
}
variable "subnet_count" {
  description = "The number of subnets to create, cannot exceed the number of AZs in the region"
  default     = ""
}


#Get the availability zones, this creates an array with the available AZs
data "aws_availability_zones" "az" {}
