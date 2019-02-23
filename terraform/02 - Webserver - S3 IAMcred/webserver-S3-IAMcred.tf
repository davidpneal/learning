#2/23/2019
#This config will stand up a simple webserver that copies its resources from an associated S3 bucket
#This version uses an IAM user to control access to the S3 bucket
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
  vpc_security_group_ids = ["${aws_security_group.WebServerSG.id}"]

  connection {
    user        = "ec2-user"
    private_key = "${file(var.private_key_path)}"
}

  #Generate the credentials file so ec2-user can access S3 using the WebsiteS3User IAM creds
  #Create the file in the home directory then move it later, trying to set the destionation to .aws/credentials doesnt work correctly
  provisioner "file" {
    content = <<EOF
[default]
aws_access_key_id = ${aws_iam_access_key.WebsiteS3User.id}
aws_secret_access_key = ${aws_iam_access_key.WebsiteS3User.secret}

EOF
    destination = "/home/ec2-user/credentials"
  }

  #Note - the file contents need to be left justified - spaces/tabs before the lines break the config file format
  provisioner "file" {
    content = <<EOF
[default]
region = us-east-1
output = json

EOF
    destination = "/home/ec2-user/config"
  }

  #Recall these commands run under the context of ec2-user
  provisioner "remote-exec" {
    inline = [
	  "sudo yum update -y",
	  "sudo yum install httpd -y",
    "mkdir /home/ec2-user/.aws",
    "mv /home/ec2-user/credentials /home/ec2-user/.aws/credentials",
    "mv /home/ec2-user/config /home/ec2-user/.aws/config",
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



#S3 Bucket

#Create the IAM user to control EC2-S3 access
resource "aws_iam_user" "WebsiteS3User" {
    name = "${var.environment_tag}-WebsiteS3User"
    force_destroy = true
}

#Create the Access key (creds) for the IAM user 
resource "aws_iam_access_key" "WebsiteS3User" {
    user = "${aws_iam_user.WebsiteS3User.name}"
}

#Security Policy - Grant RO access for the WebsiteS3User to the S3 bucket
#This command (aws_iam_user_policy) will create the WebsiteS3User-Policy as an inline policy on the IAM user
resource "aws_iam_user_policy" "WebsiteS3User-Policy" {
    name = "WebsiteS3User-Policy"
    user = "${aws_iam_user.WebsiteS3User.name}"

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
  } #End IAM User Policy


#Create the S3 bucket
resource "aws_s3_bucket" "WebsiteResources" {
  bucket = "${var.environment_tag}-${var.bucket_name}"
  acl = "private"
  force_destroy = true

  policy = <<EOF
{
    "Version": "2008-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Principal": {
                "AWS": "${aws_iam_user.WebsiteS3User.arn}"
            },
            "Action": "s3:GetObject",
            "Resource": [
                "arn:aws:s3:::${var.environment_tag}-${var.bucket_name}",
                "arn:aws:s3:::${var.environment_tag}-${var.bucket_name}/*"
            ]
        }
    ]
  }
  EOF

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
