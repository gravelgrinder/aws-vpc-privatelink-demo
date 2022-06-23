### Consumer Account Resources
provider "aws" {
  alias   = "main-acct"
  profile = "default"
  region  = "us-east-1"
}


###############################################################################
### djl-win-server
###############################################################################
resource "aws_security_group" "ec2_sg1" {
  provider   = aws.main-acct
  name        = "tf_sg1"
  description = "Security Group for djl-win-server. Created by Terraform"
  vpc_id      = var.main-vpcid

  tags = {
    Name = "tf_sg1"
  }  
}

resource "aws_security_group_rule" "allow_rdp_ingress1" {
  provider          = aws.main-acct
  type              = "ingress"
  description       = "Allow RDP Connections from the OpenVPN Server SG"
  from_port         = 3389
  to_port           = 3389
  protocol          = "tcp"
  source_security_group_id = var.main-openvpn-sg-id
  security_group_id = aws_security_group.ec2_sg1.id
}

resource "aws_security_group_rule" "allow_egress1" {
  provider          = aws.main-acct
  type              = "egress"
  description       = "Allow all outbound connections"
  from_port         = -1
  to_port           = -1
  protocol          = -1
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ec2_sg1.id
}

resource "aws_instance" "djl-win-server" {
  provider                    = aws.main-acct
  ami                         = "ami-0e2c8caa770b20b08" # us-east-1
  instance_type               = "t3.large"
  subnet_id                   = var.main-ec2-subnet-id
  #availability_zone          = "us-east-1"
  associate_public_ip_address = "false"
  key_name                    = "DemoVPC_Key_Pair"
  vpc_security_group_ids      = [aws_security_group.ec2_sg1.id]
  get_password_data           = "true"

  tags = {
    Name = "djl-win-server"
  }
}
###############################################################################


###############################################################################
### djl-win-server2
###############################################################################
resource "aws_security_group" "ec2_sg2" {
  provider   = aws.main-acct
  name        = "tf_sg2"
  description = "Security Group for djl-win-server2. Created by Terraform"
  vpc_id      = var.main-vpcid

  tags = {
    Name = "tf_sg2"
  }  
}

resource "aws_security_group_rule" "allow_rdp_ingress2" {
  provider          = aws.main-acct
  type              = "ingress"
  description       = "Allow RDP Connections from the OpenVPN Server SG"
  from_port         = 3389
  to_port           = 3389
  protocol          = "tcp"
  source_security_group_id = var.main-openvpn-sg-id
  security_group_id = aws_security_group.ec2_sg2.id
}

resource "aws_security_group_rule" "allow_egress2" {
  provider          = aws.main-acct
  type              = "egress"
  description       = "Allow all outbound connections"
  from_port         = -1
  to_port           = -1
  protocol          = -1
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ec2_sg2.id
}

resource "aws_instance" "djl-win-server2" {
  provider                    = aws.main-acct
  ami                         = "ami-0e2c8caa770b20b08" # us-east-1
  instance_type               = "t3.large"
  subnet_id                   = var.main-ec2-subnet-id
  #availability_zone          = "us-east-1"
  associate_public_ip_address = "false"
  key_name                    = "DemoVPC_Key_Pair"
  vpc_security_group_ids      = [aws_security_group.ec2_sg2.id]
  get_password_data           = "true"

  tags = {
    Name = "djl-win-server2"
  }
}
###############################################################################