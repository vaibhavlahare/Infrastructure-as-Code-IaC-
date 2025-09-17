# Launch Template
resource "aws_launch_template" "app" {
  name_prefix   = "${var.project}-lt-"
  image_id      = var.ami_id
  instance_type = var.instance_type

  # Use security_group_ids instead of names
  security_group_ids = [aws_security_group.ec2_sg.id]

  user_data = base64encode(<<-EOT
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>Terraform EC2 Instance</h1>" > /var/www/html/index.html
              EOT
  )
}

# Auto Scaling Group
resource "aws_autoscaling_group" "asg" {
  desired_capacity    = var.desired_capacity
  max_size            = var.max_size
  min_size            = var.min_size
  vpc_zone_identifier = aws_subnet.public[*].id  # must be in same VPC as SG

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"   # Terraform will pick latest LT version
  }

  tag {
    key                 = "Name"
    value               = "${var.project}-asg"
    propagate_at_launch = true
  }
}
