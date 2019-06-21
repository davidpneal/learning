#6/21/2019
#VPC components to provision a system across multiple AZ's

resource "aws_vpc" "vpc" {
  cidr_block           = "${var.network_address_space}"
  enable_dns_hostnames = true

  tags {
    Name        = "${var.environment_tag}-vpc"
    Environment = "${var.environment_tag}"
  }
}

#Bind the igw to the vpc
resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.vpc.id}"

  tags {
    Name        = "${var.environment_tag}-igw"
    Environment = "${var.environment_tag}"
  }
}

#Create the subnets
resource "aws_subnet" "subnet" {
  count                   = "${var.subnet_count}"
  #Parent network space, cidr offset - add this to 16 to get /24, index (first subnet)
  cidr_block              = "${cidrsubnet(var.network_address_space,8,count.index)}"
  vpc_id                  = "${aws_vpc.vpc.id}"
  map_public_ip_on_launch = "true"
  availability_zone       = "${data.aws_availability_zones.az.names[count.index]}"

  tags {
    Name        = "${var.environment_tag}-${data.aws_availability_zones.az.names[count.index]}-subnet"
    Environment = "${var.environment_tag}"
  }
}

#Create a route table
resource "aws_route_table" "route-table" {
  vpc_id = "${aws_vpc.vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.igw.id}"
  }

  tags {
    Name        = "${var.environment_tag}-route-table"
    Environment = "${var.environment_tag}"
  }
}

#Associate the route table to the subnet
resource "aws_route_table_association" "route-table-subnet" {
  count          = "${var.subnet_count}"
  #The wildcard in this command will return all of the subnets that are part of the aws_subnet.subnet variable
  #The element command will iterate this list using count as an index
  subnet_id      = "${element(aws_subnet.subnet.*.id,count.index)}"
  route_table_id = "${aws_route_table.route-table.id}"
}
