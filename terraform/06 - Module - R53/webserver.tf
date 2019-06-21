#6/21/2019
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


#Set provider
provider "aws" {
  region = "us-east-1"
}


module "networking" {
  source = "\\networking"

  environment_tag       = "${var.environment_tag}"
  network_address_space = "${var.network_address_space}"
  subnet_count          = "${var.subnet_count}"
}



#Security Groups #######################################################################################

#Security Group to control access to the web server
resource "aws_security_group" "WebServerSG" {
  name   = "WebServerSG"
  vpc_id = "${module.networking.vpc_id}"

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
  vpc_id      = "${module.networking.vpc_id}"

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
  #Subnet_ids is a data structure that contains multiple id's
  subnets         = ["${module.networking.subnet_ids}"]
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
  subnet_id     = "${element(module.networking.subnet_ids,count.index % var.subnet_count)}" #Use % to divide the instances among the subnets
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