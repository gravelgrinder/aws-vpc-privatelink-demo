### Provider Account Resources
provider "aws" {
  alias   = "cross-acct"
  profile = "default"
  region  = "us-east-1"

  assume_role {
    role_arn = "arn:aws:iam::758373647921:role/djl-tf-assume_role"
  }
}



###############################################################################
### djl-database-1
###############################################################################
resource "aws_security_group" "db_sg" {
  provider    = aws.cross-acct
  name        = "tf_db_sg"
  description = "Database Security Group created by Terraform"
  vpc_id      = var.cross-vpcid

  tags = {
    Name = "tf_db_sg"
  }
}

resource "aws_security_group_rule" "allow_ingress_nlb" {
  provider          = aws.cross-acct
  type              = "ingress"
  description       = "Allow inbound connections from the private subnets."
  from_port         = 3306
  to_port           = 3306
  protocol          = "tcp"
  cidr_blocks       = var.cross-private-subnet-cidr-blocks
  security_group_id = aws_security_group.db_sg.id
}

resource "aws_security_group_rule" "allow_ingress_from_jump_server" {
  provider          = aws.cross-acct
  type              = "ingress"
  description       = "Allow inbound connections from the jump server in the Public subnet."
  from_port         = 3306
  to_port           = 3306
  protocol          = "tcp"
  source_security_group_id = aws_security_group.jump-server-sg.id
  security_group_id = aws_security_group.db_sg.id
}


resource "aws_security_group_rule" "allow_egress_nlb" {
  provider          = aws.cross-acct
  type              = "egress"
  description       = "Allow all outbound connections"
  from_port         = -1
  to_port           = -1
  protocol          = -1
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.db_sg.id
}

resource "aws_db_subnet_group" "db_subnet_group" {
  provider   = aws.cross-acct
  name       = "tf_db_group"
  subnet_ids = var.cross-private-subnet-ids-ALL
}

resource "aws_db_instance" "mysqlrds" {
  provider             = aws.cross-acct
  depends_on           = [aws_security_group.db_sg]
  allocated_storage    = 10
  storage_encrypted    = true
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.xlarge"
  publicly_accessible  = false
  identifier           = "djl-database-1"
  db_name              = "djl"
  username             = "foo"
  password             = "foobarbaz"
  parameter_group_name = "djl-pg"
  iam_database_authentication_enabled = "true"
  apply_immediately                   = "true"
  vpc_security_group_ids              = [aws_security_group.db_sg.id]
  db_subnet_group_name                = aws_db_subnet_group.db_subnet_group.id
  multi_az                            = false
  #backup_retention_period             = 35
  skip_final_snapshot                 = true
  tags = {Name = "djl-database-1", phidb = true, s3export = true, storagetier = "s3glacier"}
  copy_tags_to_snapshot = true
}
###############################################################################


###############################################################################
### NLB
###############################################################################
resource "aws_lb_target_group" "tg" {
  provider    = aws.cross-acct
  name        = "tf-lb-tg"
  port        = 3306
  protocol    = "TCP"
  target_type = "ip"
  vpc_id      = var.cross-vpcid
}

resource "aws_lb_target_group_attachment" "tg_rds_target" {
  provider         = aws.cross-acct
  depends_on       = [aws_lb_target_group.tg]
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = "10.1.50.235" ##TODO - Change Me
  port             = 3306
}

resource "aws_lb" "nlb" {
  provider           = aws.cross-acct
  name               = "tf-nlb"
  internal           = true
  load_balancer_type = "network"
  subnets            = var.cross-private-subnet-ids-ALL

  enable_deletion_protection = false

  tags = {
    Name = "tf-nlb"
  }
}

resource "aws_lb_listener" "nlb_listener" {
  provider          = aws.cross-acct
  depends_on        = [aws_lb.nlb, aws_lb_target_group.tg, aws_lb_target_group_attachment.tg_rds_target]
  load_balancer_arn = aws_lb.nlb.arn
  port              = 3001
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}
###############################################################################