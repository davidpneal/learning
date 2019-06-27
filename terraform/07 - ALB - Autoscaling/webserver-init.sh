#!/bin/bash
#6/27/2019
#This script is run under root permissions when the ASG instantiates a new machine

yum update -y
yum install httpd -y
echo "<html><body><h1>Hello World</h1>Welcome to " >> index.html
curl http://169.254.169.254/latest/meta-data/public-ipv4 >> index.html
echo "</body></html>" >> index.html
#Keep in mind the perms for the file will only allow write access to root
mv index.html /var/www/html/
service httpd start
chkconfig httpd on