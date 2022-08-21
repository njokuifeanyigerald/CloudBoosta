#!/bin/bash
echo "Installing Apache ###############"
sudo yum update -y 
sudo yum install httpd -y
sudo service https start
sudo service https status
echo "hello World from ${hostname -f}" > /var/www/html/index.html