# Security group for ALB
resource "aws_security_group" "alb_sg" {
  name   = "tf-iac-alb-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "tf-iac-alb-sg" }
}

# Security group for EC2
resource "aws_security_group" "ec2_sg" {
  name   = "tf-iac-ec2-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "tf-iac-ec2-sg" }
}

# Launch Template
resource "aws_launch_template" "ec2_lt" {
  name_prefix   = "tf-iac-lt"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  user_data = base64encode(file("${path.module}/scripts/user_data.sh"))

  tag_specifications {
    resource_type = "instance"
    tags = { Name = "tf-iac-ec2" }
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "asg" {
  desired_capacity     = var.asg_desired_capacity
  max_size             = var.asg_max_size
  min_size             = var.asg_min_size
  vpc_zone_identifier  = aws_subnet.public[*].id
  launch_template {
    id      = aws_launch_template.ec2_lt.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.tg.arn]
  health_check_type = "EC2"

  tag {
    key                 = "Name"
    value               = "tf-iac-asg-instance"
    propagate_at_launch = true
  }
}

# Application Load Balancer
resource "aws_lb" "alb" {
  name               = "tf-iac-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = aws_subnet.public[*].id
}

resource "aws_lb_target_group" "tg" {
  name     = "tf-iac-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

# Get Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}
