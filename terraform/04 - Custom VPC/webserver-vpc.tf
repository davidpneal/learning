#3/2/2019
#This config demonstrates configuring a VPC and its components to support a simple webserver
#Requires the keypair to already exist in AWS


#Variables defined in terraform.tfvars
variable "private_key_path" {}
variable "keypair_name" {}
variable "public_ip" {}
variable "bucket_name" {
  default = "dpn-websiteresources"
}
variable "environment_tag" {
  default = "lab"
}
variable "network_address_space" {
  default = "10.1.0.0/16"
}
variable "az" {
  default = "us-east-1a"
}

#Set provider
provider "aws" {
  region = "us-east-1"
}



# VPC

resource "aws_vpc" "vpc" {
  cidr_block = "${var.network_address_space}"
  enable_dns_hostnames = true

  tags {
    Name = "${var.environment_tag}-vpc"
    Environment = "${var.environment_tag}"
  }
}

#Bind the igw to the vpc
resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.vpc.id}"

  tags {
    Name = "${var.environment_tag}-igw"
    Environment = "${var.environment_tag}"
  }

}

#Create the subnet
resource "aws_subnet" "subnet" {
  #Parent network space, cidr offset - add this to 16 to get /24, index (first subnet)
  cidr_block = "${cidrsubnet(var.network_address_space,8,0)}"
  vpc_id = "${aws_vpc.vpc.id}"
  map_public_ip_on_launch = "true"
  availability_zone = "${var.az}"

  tags {
    Name = "${var.environment_tag}-${var.az}-subnet"
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
    Name = "${var.environment_tag}-route-table"
    Environment = "${var.environment_tag}"
  }

}

#Associate the route table to the subnet
resource "aws_route_table_association" "route-table-subnet" {
  #First element in the subnet list
  subnet_id = "${element(aws_subnet.subnet.*.id,0)}"
  route_table_id = "${aws_route_table.route-table.id}"
}



#Security Groups

#Security Group to control access to the web server
resource "aws_security_group" "WebServerSG" {
  name        = "WebServerSG"
  vpc_id      = "${aws_vpc.vpc.id}"

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
    Name = "${var.environment_tag}-WebServerSG"
    Environment = "${var.environment_tag}"
  }

} #End Security Group



#EC2 Instance
resource "aws_instance" "WebServer01" {
  ami           = "ami-035be7bafff33b6b6"
  instance_type = "t2.micro"
  key_name      = "${var.keypair_name}"
  subnet_id     = "${element(aws_subnet.subnet.*.id,0)}"
  vpc_security_group_ids = ["${aws_security_group.WebServerSG.id}"]
  
  connection {
    user        = "ec2-user"
    private_key = "${file(var.private_key_path)}"
  }

  tags {
    Name = "${var.environment_tag}-WebServer01"
    Environment = "${var.environment_tag}"
  }

  #Recall these commands run under the context of ec2-user
  provisioner "remote-exec" {
    script = "webserver-init.sh"
  }

} #End Instance



#Output
output "aws_instance_public_dns" {
    value = "${aws_instance.WebServer01.public_dns}"
}
