#2/10/2019
#This config requires the keypair to already exist in AWS
#This version of the config will also create a basic Security Group


#Variables definined in terraform.tfvars
variable "private_key_path" {}
variable "keypair_name" {}
variable "public_ip" {}


#AWS Provider
provider "aws" {
  region     = "us-east-1"
}


#Resources

#Import the default VPC so it can be managed by Terraform
resource "aws_default_vpc" "DefaultVPC" {}

#Security Group
resource "aws_security_group" "WebServerSG" {
  name        = "WebServerSG"
  vpc_id      = "${aws_default_vpc.DefaultVPC.id}"

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
}

#Instance
resource "aws_instance" "webserver01" {
  ami           = "ami-035be7bafff33b6b6"
  instance_type = "t2.micro"
  key_name      = "${var.keypair_name}"
  vpc_security_group_ids = ["${aws_security_group.WebServerSG.id}"]

  connection {
    user        = "ec2-user"
    private_key = "${file(var.private_key_path)}"
}

  provisioner "remote-exec" {
    inline = [
	  "sudo yum update -y",
	  "sudo yum install httpd -y",
	  "echo '<html><h1>Hello World</h1></html>' | sudo tee /var/www/html/index.html",
	  "sudo service httpd start",
	  "sudo chkconfig httpd on"
    ]
  }
}


#Output
output "aws_instance_public_dns" {
    value = "${aws_instance.webserver01.public_dns}"
}
