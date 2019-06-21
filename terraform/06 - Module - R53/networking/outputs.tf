#6/21/2019

#This will export a data structure that contains all of the subnets
output "subnet_ids" {
  value = "${aws_subnet.subnet.*.id}"
}

output "vpc_id" {
  value = "${aws_vpc.vpc.id}"
}