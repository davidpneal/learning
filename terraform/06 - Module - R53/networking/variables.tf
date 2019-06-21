#6/21/2019

variable "environment_tag" {}
variable "network_address_space" {}
variable "subnet_count" {}


#Get the availability zones, this creates an array with the available AZs
data "aws_availability_zones" "az" {}
