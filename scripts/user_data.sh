#!/bin/bash
# Install Apache and PHP (or Node.js if needed)
yum update -y
yum install -y httpd

# Start Apache
systemctl start httpd
systemctl enable httpd

# Simple index.html
echo "<h1>Deployed via Terraform in ASG</h1>" > /var/www/html/index.html
