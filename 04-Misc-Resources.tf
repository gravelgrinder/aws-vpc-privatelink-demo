### Resources created to test out the NLB and RDS Instance.  These resources are not necessary once the POC is up and running.

###############################################################################
### djl-jump-server
###############################################################################
resource "aws_security_group" "jump-server-sg" {
  provider   = aws.cross-acct
  name        = "tf_jump_server_sg"
  description = "Security Group for djl-jump-server. Created by Terraform"
  vpc_id      = var.cross-vpcid

  tags = {
    Name = "tf_jump_server_sg"
  }  
}

resource "aws_security_group_rule" "js_ingress" {
  provider          = aws.cross-acct
  type              = "ingress"
  description       = "Allow RDP Connections from Home IP Address"
  from_port         = 3389
  to_port           = 3389
  protocol          = "tcp"
  cidr_blocks       = ["208.95.71.55/32"]
  security_group_id = aws_security_group.jump-server-sg.id
}

resource "aws_security_group_rule" "js_egress" {
  provider          = aws.cross-acct
  type              = "egress"
  description       = "Allow all outbound connections"
  from_port         = -1
  to_port           = -1
  protocol          = -1
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.jump-server-sg.id
}

resource "aws_instance" "djl-jump-server" {
  provider                    = aws.cross-acct
  ami                         = "ami-0e2c8caa770b20b08" # us-east-1
  instance_type               = "t3.large"
  subnet_id                   = var.cross-ec2-public-subnet-id
  #availability_zone          = "us-east-1"
  associate_public_ip_address = "true"
  key_name                    = "AWSomeBuilder_Key_Pair"
  vpc_security_group_ids      = [aws_security_group.jump-server-sg.id]

  tags = {
    Name = "djl-jump-server"
  }
}
###############################################################################