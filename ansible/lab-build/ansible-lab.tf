#3/3/2019
#This terraform file will build a linux control machine with ansible installed
#It will have a S3 bucket where ansible playbooks can be uploaded
#Requires the keypair to already exist in AWS


#Variables defined in terraform.tfvars
variable "private_key_path" {}
variable "keypair_name" {}
variable "public_ip" {}
variable "network_address_space" {
  default = "10.1.0.0/16"
}
variable "az" {
  default = "us-east-1a"
}
variable "bucket_name" {
  default = "dpn-ansiblelab"
}


#AWS Provider
provider "aws" {
  region = "us-east-1"
}



# VPC

resource "aws_vpc" "vpc" {
  cidr_block = "${var.network_address_space}"
  enable_dns_hostnames = true

  tags {
    Name = "AnsibleLab-vpc"
  }
}

#Bind the igw to the vpc
resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.vpc.id}"

  tags {
    Name = "AnsibleLab-igw"
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
    Name = "AnsibleLab-${var.az}-subnet"
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
    Name = "AnsibleLab-route-table"
  }

}

#Associate the route table to the subnet
resource "aws_route_table_association" "route-table-subnet" {
  #First element in the subnet list
  subnet_id = "${element(aws_subnet.subnet.*.id,0)}"
  route_table_id = "${aws_route_table.route-table.id}"
}



#Security Group to control access to Ansible-Lab
resource "aws_security_group" "Ansible-Lab-SG" {
  name        = "Ansible-Lab-SG"
  vpc_id      = "${aws_vpc.vpc.id}"

  # SSH access from a whitelisted address
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.public_ip}"]
  }

  # Outbound access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "AnsibleLabSG"
  }

} #End Security Group



#Instance
resource "aws_instance" "Ansible-Lab" {
  ami           = "ami-035be7bafff33b6b6"
  instance_type = "t2.micro"
  key_name      = "${var.keypair_name}"
  subnet_id     = "${element(aws_subnet.subnet.*.id,0)}"
  iam_instance_profile = "${aws_iam_instance_profile.EC2-S3-RoleInstance.name}"
  vpc_security_group_ids = ["${aws_security_group.Ansible-Lab-SG.id}"]

  connection {
    user        = "ec2-user"
    private_key = "${file(var.private_key_path)}"
  }


  #Recall these commands run under the context of ec2-user
  provisioner "remote-exec" {
    script = "ansible-lab-build.sh"
  }

  tags {
    Name = "AnsibleLab"
  }

} #End Instance



#S3 Bucket

#Create the IAM Role to control EC2-S3 access
#The assume role policy grants EC2 Allow access to whatever its applied to
resource "aws_iam_role" "EC2-S3Role" {
    name = "EC2-S3Role"

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

#IAM Security Policy - grants access to the S3 bucket
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
                  "s3:*" 
              ],
              "Resource": [
                  "arn:aws:s3:::${var.bucket_name}",
                  "arn:aws:s3:::${var.bucket_name}/*"
              ]
          }
      ]
    }
    EOF
} #End S3 access policy

#Attach the S3 permissions policy to the role
resource "aws_iam_policy_attachment" "EC2-S3-Role-Attach" {
  name       = "EC2-S3-Role-Attachment"
  roles      = ["${aws_iam_role.EC2-S3Role.name}"]
  policy_arn = "${aws_iam_policy.S3-Access-Policy.arn}"
}

#Create the IAM Role Instance Profile - this is what is actually attached to the EC2 instance
resource "aws_iam_instance_profile" "EC2-S3-RoleInstance" {
  name  = "EC2-S3-RoleInstance"
  role = "${aws_iam_role.EC2-S3Role.name}"
}

#Create the S3 bucket
resource "aws_s3_bucket" "AnsibleLabBucket" {
  bucket = "${var.bucket_name}"
  acl = "private" ##LOOK INTO THIS #################################
  force_destroy = true

  tags {
    Name = "${var.bucket_name}"
  }

}



#Output
output "aws_instance_public_dns" {
    value = "${aws_instance.Ansible-Lab.public_dns}"
}
