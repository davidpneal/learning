#6/28/2019
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

#The maximum number of instances that the ASG will provision
variable "max_instances" {
  default = 4
}

#The minimum number of instances that the ASG will provision
variable "min_instances" {
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



#Application Load Balancer ##################################################################################

#Security Group to control access to the load balancer
resource "aws_security_group" "ALB-SG" {
  name        = "ALB-SG"
  vpc_id      = "${module.networking.vpc_id}"

  #HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #Outbound access
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
}

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



#EC2 - AutoScaling Group ####################################################################################

#Security Group to control access to the web server
resource "aws_security_group" "WebServer-SG" {
  name   = "WebServer-SG"
  vpc_id = "${module.networking.vpc_id}"

  #SSH access from a whitelisted address
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.public_ip}"]
  }

  #HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #Outbound access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name        = "${var.environment_tag}-WebServer-SG"
    Environment = "${var.environment_tag}"
  }
}

#Define the Launch Configuration
resource "aws_launch_configuration" "Launch-Config" {
  name_prefix            = "Website-LC-" #TF documentation recc not using a name since the LC is recreated if changed
  image_id               = "ami-035be7bafff33b6b6" #This AMI is ok for the US-E1 Region
  instance_type          = "t2.micro"
  security_groups        = ["${aws_security_group.WebServer-SG.id}"]
  key_name               = "${var.keypair_name}"

  #User data takes the bootstrap script - documentation indicates this can be a cloud-init script or a standard shell script 
  user_data = "${file("webserver-init.sh")}"

  lifecycle {
    create_before_destroy = true #If changed, create the new LC before destroying the old one
  }
}

#Create the AutoScaling Group
resource "aws_autoscaling_group" "ASG" {
  name                  = "WebServer-ASG"
  launch_configuration  = "${aws_launch_configuration.Launch-Config.id}"
  vpc_zone_identifier   = ["${module.networking.subnet_ids}"] #list of subnet IDs to launch resources into
  min_size              = "${var.min_instances}"
  max_size              = "${var.max_instances}"
  health_check_type     = "ELB"
  enabled_metrics       = [""] #Enables Group Metrics Collection for all metrics
  
  tag {
    key = "Name"
    value = "${var.environment_tag}-ASG-WebServer"
    propagate_at_launch = true #Required so the ASG can propagate the tag to the EC2 instances it creates
  }
}

#Scale Up Policy and Alarm
resource "aws_autoscaling_policy" "Scale-Up" {
  name                   = "Scale-Up-Policy"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = "${aws_autoscaling_group.ASG.name}"
}

resource "aws_cloudwatch_metric_alarm" "Scale-Up-Alarm" {
  alarm_name                = "Scale-Up-Alarm"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = "2"
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = "120"
  statistic                 = "Average"
  threshold                 = "80"
  insufficient_data_actions = []

  dimensions {
    AutoScalingGroupName = "${aws_autoscaling_group.ASG.name}"
  }

  alarm_description = "EC2 High CPU Utilization"
  alarm_actions     = ["${aws_autoscaling_policy.Scale-Up.arn}"]
}

#Scale Down Policy and Alarm
resource "aws_autoscaling_policy" "Scale-Down" {
  name                   = "Scale-Down-Policy"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 600
  autoscaling_group_name = "${aws_autoscaling_group.ASG.name}"
}

resource "aws_cloudwatch_metric_alarm" "Scale-Down-Alarm" {
  alarm_name                = "Scale-Down-Alarm"
  comparison_operator       = "LessThanThreshold"
  evaluation_periods        = "5"
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = "120"
  statistic                 = "Average"
  threshold                 = "30"
  insufficient_data_actions = []

  dimensions {
    AutoScalingGroupName = "${aws_autoscaling_group.ASG.name}"
  }

  alarm_description = "EC2 Low CPU Utilization"
  alarm_actions     = ["${aws_autoscaling_policy.Scale-Down.arn}"]
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