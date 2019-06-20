#6/20/2019
#Tested to work with Terraform .11.11 - version .12.2 does not work as written

#A simple website running on a load balanced platform
#Also publishes the Load Balancer address as a subdomain for easy access
#Requires the keypair to already exist in AWS


#Variables defined in terraform.tfvars
variable "private_key_path" {}
variable "keypair_name" {}
variable "public_ip" {}

variable "environment_tag" {
  default = "lab06"
}

variable "network_address_space" {
  default = "10.1.0.0/16"
}

#The total number of instances to provision
variable "instance_count" {
  default = 2
}

#The number of subnets - each subnet will be placed into a different AZ
#Note that this value cannot be greater than the number of AZs in the Region
variable "subnet_count" {
  default = 2
}

#The subdomain name for this website, will be appended to the apex domain specified below
variable "dns_subdomain" {
  default = "lab"
}

#Get the Route53 zone as this resource already exists in AWS
data "aws_route53_zone" "primary" {
  name = "davidpneal.com"
}

#Get the availability zones, this creates an array with the available AZs
data "aws_availability_zones" "az" {}

#Set provider
provider "aws" {
  region = "us-east-1"
}



# VPC ##################################################################################################

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



#Security Groups #######################################################################################

#Security Group to control access to the web server
resource "aws_security_group" "WebServerSG" {
  name   = "WebServerSG"
  vpc_id = "${aws_vpc.vpc.id}"

  # SSH access from a whitelisted address
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.public_ip}"]
  }

  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name        = "${var.environment_tag}-WebServerSG"
    Environment = "${var.environment_tag}"
  }

}


#Security Group to control access to the elastic load balancer
resource "aws_security_group" "ELB-SG" {
  name        = "ELB-SG"
  vpc_id      = "${aws_vpc.vpc.id}"

  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name        = "${var.environment_tag}-ELB-SG"
    Environment = "${var.environment_tag}"
  }

} #End Security Group



#Elastic Load Balancer #################################################################################
#aws_elb will create a Classic ELB
resource "aws_elb" "LoadBalancer" {
  name            = "LoadBalancer"
  subnets         = ["${aws_subnet.subnet.*.id}"]
  security_groups = ["${aws_security_group.ELB-SG.id}"]
  instances       = ["${aws_instance.WebServer.*.id}"]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  tags {
    Name        = "${var.environment_tag}-elb"
    Environment = "${var.environment_tag}"
  }
}



#EC2 Instance ##########################################################################################
resource "aws_instance" "WebServer" {
  count         = "${var.instance_count}"
  ami           = "ami-035be7bafff33b6b6" #This AMI is ok for the US-E1 Region
  instance_type = "t2.micro"
  key_name      = "${var.keypair_name}"
  subnet_id     = "${element(aws_subnet.subnet.*.id,count.index % var.subnet_count)}" #Use % to divide the instances among the subnets
  vpc_security_group_ids = ["${aws_security_group.WebServerSG.id}"]
  
  connection {
    user        = "ec2-user"
    private_key = "${file(var.private_key_path)}"
  }

  tags {
    Name        = "${var.environment_tag}-WebServer-${count.index}"
    Environment = "${var.environment_tag}"
  }

  #Recall these commands run under the context of ec2-user
  provisioner "remote-exec" {
    script = "webserver-init.sh"
  }

} #End Instance



#Alias the Load Balancer to a subdomain name
resource "aws_route53_record" "alias_r53_elb" {
  zone_id = "${data.aws_route53_zone.primary.zone_id}"
  name    = "${var.dns_subdomain}"
  type    = "A"

  alias {
    name                   = "${aws_elb.LoadBalancer.dns_name}"
    zone_id                = "${aws_elb.LoadBalancer.zone_id}"
    evaluate_target_health = true
  }
}