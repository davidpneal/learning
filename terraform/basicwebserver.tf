#2/10/2019
#This config requires the keypair and security groups to already exist in AWS


#Variables
variable "private_key_path" {}
variable "keypair_name" {}


#AWS Provider
provider "aws" {
  region     = "us-east-1"
}


#Resources
resource "aws_instance" "webserver01" {
  ami           = "ami-035be7bafff33b6b6"
  instance_type = "t2.micro"
  key_name      = "${var.keypair_name}"
  vpc_security_group_ids = ["WebDMZ"]

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
