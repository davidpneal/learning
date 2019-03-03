#!/bin/bash
#3/2/2019

sudo yum update -y
sudo yum install httpd -y
echo "<html><body><h1>Hello World</h1>Welcome to " >> index.html
curl http://169.254.169.254/latest/meta-data/public-ipv4 >> index.html
echo "</body></html>" >> index.html
sudo mv /home/ec2-user/index.html /var/www/html/
sudo service httpd start
sudo chkconfig httpd on