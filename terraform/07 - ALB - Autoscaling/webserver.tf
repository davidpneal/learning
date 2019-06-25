#6/25/2019
#Tested to work with Terraform .11.11 - version .12.2 does not work as written

#A simple website running on a load balanced platform with autoscaling
#Also publishes the Load Balancer address as a subdomain for easy access
#Requires the keypair to already exist in AWS


#Variables defined in terraform.tfvars
variable "private_key_path" {}
variable "keypair_name" {}
variable "public_ip" {}



variable "environment_tag" {
  default = "lab07"
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
resource "aws_security_group" "ALB-SG" {
  name        = "ALB-SG"
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
    Name        = "${var.environment_tag}-ALB-SG"
    Environment = "${var.environment_tag}"
  }
} #End Security Group



#Application Load Balancer #################################################################################
resource "aws_lb" "LoadBalancer" {
  name               = "Website-ALB"
  internal           = false
  load_balancer_type = "application"
  #Subnet_ids is a data structure that contains multiple id's
  subnets            = ["${module.networking.subnet_ids}"]
  security_groups    = ["${aws_security_group.ALB-SG.id}"]

  tags {
    Name        = "${var.environment_tag}-alb"
    Environment = "${var.environment_tag}"
  }
}

#Define a listener config for the ALB
resource "aws_lb_listener" "FE-Listener" {
  load_balancer_arn = "${aws_lb.LoadBalancer.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.FE-TargetGroup.arn}"
  }
}

#Create a Target Group to point the ALB to
resource "aws_lb_target_group" "FE-TargetGroup" {
  name     = "FE-TargetGroup"  
  port     = "80"  
  protocol = "HTTP"  
  vpc_id   = "${module.networking.vpc_id}"
    
  tags {
    Name        = "${var.environment_tag}-targetgroup"
    Environment = "${var.environment_tag}"
  }  
 
  health_check {    
    healthy_threshold   = 2    
    unhealthy_threshold = 3    
    timeout             = 5    
    interval            = 10    
    path                = "/index.html"    
    port                = "80"  
  }
}

#Attach the Target Group to the Autoscaling Group
resource "aws_autoscaling_attachment" "TG-ASG-Attach" {
  alb_target_group_arn   = "${aws_lb_target_group.FE-TargetGroup.arn}"
  autoscaling_group_name = "${aws_autoscaling_group.ASG.id}"
}


#EC2 Instance ##########################################################################################
#resource "aws_instance" "WebServer" { 
#  count         = "${var.instance_count}"
#  ami           = "ami-035be7bafff33b6b6" #This AMI is ok for the US-E1 Region
#  instance_type = "t2.micro"
#  key_name      = "${var.keypair_name}"
#  subnet_id     = "${element(module.networking.subnet_ids,count.index % var.subnet_count)}" #Use % to divide the instances among the subnets
#  vpc_security_group_ids = ["${aws_security_group.WebServerSG.id}"]
  
#  connection {
#    user        = "ec2-user"
#    private_key = "${file(var.private_key_path)}"
#  }

#  tags {
#    Name        = "${var.environment_tag}-WebServer-${count.index}"
#    Environment = "${var.environment_tag}"
#  }

  #Recall these commands run under the context of ec2-user
#  provisioner "remote-exec" {
#    script = "webserver-init.sh"
#  }
#} #End Instance



# Define the Launch Configuration
resource "aws_launch_configuration" "Launch-Config" {
  name                   = "Website-Launch-Config"
  image_id               = "ami-035be7bafff33b6b6" #This AMI is ok for the US-E1 Region
  instance_type          = "t2.micro"
  security_groups        = ["${aws_security_group.WebServerSG.id}"]
  key_name               = "${var.keypair_name}"

  ####CHANGE THIS TO THE SCRIPT ~prob needs to be changes to work with the ASG 
  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install httpd -y
              echo "<html><body><h1>Hello World</h1>Welcome to " >> index.html
              curl http://169.254.169.254/latest/meta-data/public-ipv4 >> index.html
              echo "</body></html>" >> index.html
              sudo mv /home/ec2-user/index.html /var/www/html/
              sudo service httpd start
              sudo chkconfig httpd on
              EOF
  lifecycle {
    create_before_destroy = true ###LOOK THIS UP
  }

}

# Create the AutoScaling Group
resource "aws_autoscaling_group" "ASG" {
  name                  = "WebServer-ASG"
  launch_configuration  = "${aws_launch_configuration.Launch-Config.id}"
  #availability_zones    = ["${data.aws_availability_zones.all.names}"] ####THIS PROB NEEDS TO BE CHAGNED TOO - OR DELETED?
  vpc_zone_identifier   = ["${module.networking.subnet_ids}"] #list of subnet IDs to launch resources into
  min_size              = 2
  max_size              = 5 ###VAR
  #target_group_arns     = ["${aws_lb.LoadBalancer.arn}"] test-might not need this, since have a separate TG association
  health_check_type     = "ELB" ###CHANGE?
  
  tag { ###CHANGE THIS - this is what the EC2 instances get named!
    key = "Name"
    value = "terraform-asg-ec2instance"
    propagate_at_launch = true #Required so the ASG can propagate the tag to the EC2 instances it creates
  }
}



#Alias the Load Balancer to a subdomain name
resource "aws_route53_record" "alias_r53_elb" {
  zone_id = "${data.aws_route53_zone.primary.zone_id}"
  name    = "${var.dns_subdomain}"
  type    = "A"

  alias {
    name                   = "${aws_lb.LoadBalancer.dns_name}"
    zone_id                = "${aws_lb.LoadBalancer.zone_id}"
    evaluate_target_health = true
  }
}