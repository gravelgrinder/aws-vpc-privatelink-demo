# aws-vpc-privatelink-demo
Demonstration of how to access a Database across accounts using VPC Interface Endpoints (via PrivateLink)

## Architecture
![alt text](https://github.com/gravelgrinder/aws-vpc-privatelink-demo/blob/main/architecture-diagram.png?raw=true)

## Prerequisite
1. Create a role to assume in the Destination (cross-acct) Account.  Use the `init/init.tf` script to create the role.
2. Make sure the user of the `main-acct` has the proper IAM policy attached to assume the role in the `cross-acct` account.
3. The `04-Misc-Resources.tf` script is not required.  It was used to provision resources to test the DB and NLB.  Remove it if you don't want to provision extra resources.

## Steps
1. Run the following to Initialize the Terraform environment.

```
terraform init
```

2. Provision the resources in the Terraform scripts

```
terraform apply
```

3. Get the RDS IP address
```
dig +short `terraform output --raw rds_address`
```

4. Confirm the correct target IP in the NLB Target Group.  Set it to the values from step #3 above and then run `terraform apply` if it's different.

5. Connect to the `djl-win-server` EC2 instance and confirm you __**can successfully**__ reach the database.  Your connection string should look like the one below.  You will have to replace the variable `vpce_dns_name` with the approprate VPC endpoint DNS name from the Terraform outputs.  __The connection should be successful.__
```
mysql --host=${vpce_dns_name} --user=foo --password=foobarbaz djl
```

6. Connect to the `djl-win-server2` EC2 instance and confirm you __**can successfully**__ reach the database.  Your connection string should look like the one below.  You will have to replace the variable `vpce_dns_name` with the approprate VPC endpoint DNS name from the Terraform outputs.  __The connection should be successful.__
```
mysql --host=${vpce_dns_name} --user=foo --password=foobarbaz djl
``` 

7. Remove the Security Group reference for `tf_sg1` from the VPCE Security Group `tf_sg3_vpce`.  Remove it from the AWS Console or run the following...
```
terraform destroy --target aws_security_group_rule.allow_db_ingress_for_ec2_sg1
```

8. Connect to the `djl-win-server` EC2 instance again and this time confirm you are __**unable**__ to reach the database.  __**The connection should time out.**__

## Notes to Consider
* Add notes here

## Clean up Resources
1. To delete the resources created from the terraform script run the following.  You will need to do this in the base directory then in the `./init` directory.
```
terraform destroy
```


## Security/Management Point of Control
1. VPC Service "Allow Principals".
2. VPC Endpoint Allow Security Group to Security Group referencing.
3. VPC Endpoint Policy

## Helpful Resources
* [Deep Dive on How to Establish Private Connectivity with AWS Private Link – AWS Online Tech Talks](https://www.youtube.com/watch?v=weN2sCKFquA)
* [AWS re:Invent 2020: VPC endpoints & PrivateLink: Optimize for security, cost & operations](https://www.youtube.com/watch?v=LNf8jjBt72Y&list=PL2yQDdvlhXf-0zqlk2CIWszLXvyxL6sHi)
* [AWS lowers data processing charges for AWS PrivateLink](https://aws.amazon.com/about-aws/whats-new/2021/07/aws-lowers-data-processing-charges-aws-privatelink/)
* [Leverage AWS PrivateLink to Securely connect Amazon RDS from On-Premise](https://someshsrivastava1983.medium.com/leverage-aws-privatelink-to-securely-connect-amazon-rds-from-on-premise-9bf4bd3184b3)
* [Control access to services using endpoint policies](https://docs.aws.amazon.com/vpc/latest/privatelink/vpc-endpoints-access.html)
* [SFDC: Secure Cross-Cloud Integrations with Private Connect](https://help.salesforce.com/s/articleView?id=sf.private_connect_overview.htm&type=5)
* [SFDC Developer Blog: Using Private Connect to Securely Connect Salesforce and AWS](https://developer.salesforce.com/blogs/2020/10/using-private-connect-to-securely-connect-data-between-salesforce-and-aws)

RDS Authentication
* [How do I allow users to authenticate to an Amazon RDS MySQL DB instance using their IAM credentials?)](https://aws.amazon.com/premiumsupport/knowledge-center/users-connect-rds-iam/)
* [Use IAM authentication to connect with SQL Workbench/J to Amazon Aurora MySQL or Amazon RDS for MySQL](https://aws.amazon.com/blogs/database/use-iam-authentication-to-connect-with-sql-workbenchj-to-amazon-aurora-mysql-or-amazon-rds-for-mysql/)



## Questions & Comments
If you have any questions or comments on the demo please reach out to me [Devin Lewis - AWS Solutions Architect](mailto:lwdvin@amazon.com?subject=AWS%2FTerraform%20FMS%20VPC%20PrivateLink%20Demo%20%28aws-vpc-privatelink-demo%29)

Of if you would like to provide personal feedback to me please click [Here](https://feedback.aws.amazon.com/?ea=lwdvin&fn=Devin&ln=Lewis)
