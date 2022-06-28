### djl-win-server Private Hostname
output "djl-win-server_ip" { value = aws_instance.djl-win-server.private_ip}
output "djl-win-server_pw" { value = rsadecrypt(aws_instance.djl-win-server.password_data,file("/Users/lwdvin/Documents/SSH_Keys/DemoVPC_Key_Pair.pem")) }

### djl-win-server2 Private Hostname
output "djl-win-server2_ip" { value = aws_instance.djl-win-server2.private_ip}
output "djl-win-server2_pw" { value = rsadecrypt(aws_instance.djl-win-server2.password_data,file("/Users/lwdvin/Documents/SSH_Keys/DemoVPC_Key_Pair.pem")) }


### RDS Endpoint
output "rds_endpoint" { value = aws_db_instance.mysqlrds.endpoint}
output "rds_address" { value = aws_db_instance.mysqlrds.address}

### NLB Endpoint
output "nlb_dns_name" { value = aws_lb.nlb.dns_name}
output "nlb_target_ip" { value = aws_lb_target_group_attachment.tg_rds_target.target_id }

### VPCE DNS Names
output "vpce_dns_names" { value = aws_vpc_endpoint.vpce.dns_entry}

#output "aws_iam_key" { value = aws_iam_access_key.rds_iam_user.id }
#output "aws_iam_secret" {  value = nonsensitive(aws_iam_access_key.rds_iam_user.secret) }

output "aws_iam_key_c" { value = aws_iam_access_key.rds_iam_user_c.id }
output "aws_iam_secret_c" {  value = nonsensitive(aws_iam_access_key.rds_iam_user_c.secret) }

output "rds_cross_account_role_arn" { value = aws_iam_role.rds_iam_role.arn }

