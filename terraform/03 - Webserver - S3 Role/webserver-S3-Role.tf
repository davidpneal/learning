#3/1/2019
#This config will stand up a simple webserver that copies its resources from an associated S3 bucket
#This version uses an IAM role to control access to the S3 bucket
#Requires the keypair to already exist in AWS


#Variables definined in terraform.tfvars
variable "private_key_path" {}
variable "keypair_name" {}
variable "public_ip" {}
variable "bucket_name" {
  default = "dpn-websiteresources"
}
variable "environment_tag" {
  default = "lab"
}


#AWS Provider
provider "aws" {
  region = "us-east-1"
}



#Import the default VPC so it can be managed by Terraform
resource "aws_default_vpc" "DefaultVPC" {}



#Security Group to control access to the web server
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

  tags {
    Name = "${var.environment_tag}-WebServerSG"
    Environment = "${var.environment_tag}"
  }

} #End Security Group



#Instance
resource "aws_instance" "WebServer01" {
  ami           = "ami-035be7bafff33b6b6"
  instance_type = "t2.micro"
  key_name      = "${var.keypair_name}"
  iam_instance_profile = "${aws_iam_instance_profile.EC2-S3-RoleInstance.name}"
  vpc_security_group_ids = ["${aws_security_group.WebServerSG.id}"]

  connection {
    user        = "ec2-user"
    private_key = "${file(var.private_key_path)}"
}


  #Recall these commands run under the context of ec2-user
  provisioner "remote-exec" {
    inline = [
	  "sudo yum update -y",
	  "sudo yum install httpd -y",
    "aws s3 cp s3://${aws_s3_bucket.WebsiteResources.id}/website/index.html .",
    "sudo mv /home/ec2-user/index.html /var/www/html/",
	  "sudo service httpd start",
	  "sudo chkconfig httpd on"
    ]
  }

  tags {
    Name = "${var.environment_tag}-WebServer01"
    Environment = "${var.environment_tag}"
  }

} #End Instance



#IAM Role

#Create the IAM Role to control EC2-S3 access
#The assume role policy grants EC2 Allow access to whatever its applied to
resource "aws_iam_role" "WebsiteS3Role" {
    name = "${var.environment_tag}-WebsiteS3Role"

    assume_role_policy= <<EOF
{
      "Version": "2012-10-17",
      "Statement": [
        {
          "Action": "sts:AssumeRole",
          "Principal": {
            "Service": "ec2.amazonaws.com"
          },
          "Effect": "Allow",
          "Sid": ""
        }
      ]
    }
    EOF
}


#Security Policy - grants access to the S3 bucket
resource "aws_iam_policy" "S3-Access-Policy" {
    name = "S3-Access-Policy"

    #Note - cannot have any leading spaces before the opening brace on the JSON block
    policy= <<EOF
{ 
      "Version": "2012-10-17",
      "Statement": [
          {
              "Effect": "Allow",
              "Action": [
                  "s3:Get*",
                  "s3:List*"
              ],
              "Resource": [
                  "arn:aws:s3:::${var.environment_tag}-${var.bucket_name}",
                  "arn:aws:s3:::${var.environment_tag}-${var.bucket_name}/*"
              ]
          }
      ]
    }
    EOF
  } #End S3 access policy

#Attach the S3 permissions policy to the role
resource "aws_iam_policy_attachment" "EC2-S3-Role-Attach" {
  name       = "EC2-S3-Role-Attachment"
  roles      = ["${aws_iam_role.WebsiteS3Role.name}"]
  policy_arn = "${aws_iam_policy.S3-Access-Policy.arn}"
}


#Create the IAM Role Instance Profile - this is what is actually attached to the EC2 instance
resource "aws_iam_instance_profile" "EC2-S3-RoleInstance" {
  name  = "EC2-S3-RoleInstance"
  roles = ["${aws_iam_role.WebsiteS3Role.name}"]
}


#S3 Bucket

#Create the S3 bucket
resource "aws_s3_bucket" "WebsiteResources" {
  bucket = "${var.environment_tag}-${var.bucket_name}"
  acl = "private"
  force_destroy = true

  tags {
    Name = "${var.environment_tag}-${var.bucket_name}"
    Environment = "${var.environment_tag}"
  }

}


#Upload objects into the bucket
resource "aws_s3_bucket_object" "Webpage-Index" {
  bucket = "${aws_s3_bucket.WebsiteResources.bucket}"
  key    = "/website/index.html"
  source = "./index.html"

}



#Output
output "aws_instance_public_dns" {
    value = "${aws_instance.WebServer01.public_dns}"
}
