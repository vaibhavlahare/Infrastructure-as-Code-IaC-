resource "aws_security_group" "rds_sg" {
  name   = "tf-iac-rds-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "tf-iac-rds-sg" }
}

resource "random_password" "db_password" {
  length  = 16
  special = true
}

resource "aws_db_subnet_group" "db_subnet" {
  name       = "tf-iac-db-subnet"
  subnet_ids = aws_subnet.private[*].id
}

resource "aws_db_instance" "mysql" {
  identifier              = "tf-iac-db"
  allocated_storage       = var.db_allocated_storage
  storage_type            = "gp2"
  engine                  = "mysql"
  engine_version          = var.db_engine_version
  instance_class          = var.db_instance_class
  db_name                 = var.db_name
  username                = var.db_username
  password                = random_password.db_password.result
  parameter_group_name    = "default.mysql8.0"
  multi_az                = var.db_multi_az
  skip_final_snapshot     = true
  vpc_security_group_ids  = [aws_security_group.rds_sg.id]
  db_subnet_group_name    = aws_db_subnet_group.db_subnet.name
}
