###############################################################################
### Security Group for VPCE
###############################################################################
resource "aws_security_group" "vpce" {
  provider   = aws.main-acct
  name        = "tf_sg3_vpce"
  description = "Security Group for the VPC endpoint. Created by Terraform"
  vpc_id      = var.main-vpcid



  tags = {
    Name = "tf_sg3_vpce"
  }  
}

### Access to the Endpoint can be controlled by Security Group Referencing.  
### Uncomment below to allow the resources belonging to the "tf_sg1" security group to talk to the VPCE.
resource "aws_security_group_rule" "allow_db_ingress_for_ec2_sg1" {
  provider          = aws.main-acct
  type              = "ingress"
  description       = "Allow MySQL (port 3001) Connections from tf_sg1 SG"
  from_port         = 3001
  to_port           = 3001
  protocol          = "tcp"
  source_security_group_id = aws_security_group.ec2_sg1.id
  security_group_id = aws_security_group.vpce.id
}

resource "aws_security_group_rule" "allow_db_ingress_for_ec2_sg2" {
  provider          = aws.main-acct
  type              = "ingress"
  description       = "Allow MySQL (port 3001) Connections from tf_sg2 SG"
  from_port         = 3001
  to_port           = 3001
  protocol          = "tcp"
  source_security_group_id = aws_security_group.ec2_sg2.id
  security_group_id = aws_security_group.vpce.id
}
###############################################################################



###############################################################################
### VPC Endpoint Service to NLB
###############################################################################
# Interface Endpoint (PrivateLink)
resource "aws_vpc_endpoint_service" "example" {
  provider                   = aws.cross-acct
  acceptance_required        = false
  allowed_principals         = ["arn:aws:iam::614129417617:root"]
  network_load_balancer_arns = [aws_lb.nlb.arn]

  tags = {
    Name = "tf-db-endpoint-service"
  }
}
###############################################################################


###############################################################################
### VPC Endpoint Allowing connectivity to VPC Endpoint Service
###############################################################################
resource "aws_vpc_endpoint" "vpce" {
  provider            = aws.main-acct
  depends_on          = [aws_vpc_endpoint_service.example]
  vpc_id              = var.main-vpcid
  service_name        = aws_vpc_endpoint_service.example.service_name
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.vpce.id]
  private_dns_enabled = false
  tags = {
    Name = "tf-vpce-2-db"
  }
}

resource "aws_vpc_endpoint_subnet_association" "vpce" {
  provider        = aws.main-acct
  for_each        = toset(var.main-private-subnet-ids)
  vpc_endpoint_id = aws_vpc_endpoint.vpce.id
  subnet_id       = "${each.key}"
}
###############################################################################