# aws-vpc-privatelink-demo
Demonstration of how to access a Database across accounts using VPC Interface Endpoints (via PrivateLink)

## Architecture
![alt text](https://github.com/gravelgrinder/aws-vpc-privatelink-demo/blob/main/images/architecture-diagram.png?raw=true)

## High Level Enterprise Rollout
![alt text](https://github.com/gravelgrinder/aws-vpc-privatelink-demo/blob/main/images/architecture-diagram-high-level.png?raw=true)

## Prerequisite
1. Create a role to assume in the Destination (cross-acct) Account.  Use the `init/init.tf` script to create the role.
2. Make sure the user of the `main-acct` has the proper IAM policy attached to assume the role in the `cross-acct` account.
3. The `04-Misc-Resources.tf` script is not required.  It was used to provision resources to test the DB and NLB.  Remove it if you don't want to provision extra resources.

## Setup Steps
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

### Verify DB Connection through VPC Endpoint
5. Connect via RDP to the `djl-win-server` EC2 instance and confirm you __**can successfully**__ reach the database.  Your connection string should look like the one below.  You will have to replace the variable `vpce_dns_name` with the approprate VPC endpoint DNS name from the Terraform outputs.  __The connection should be successful.__
```
mysql --host=${vpce_dns_name} --user=foo --password=foobarbaz djl
```

6. Connect via RDP to the `djl-win-server2` EC2 instance and confirm you __**can successfully**__ reach the database.  Your connection string should look like the one below.  You will have to replace the variable `vpce_dns_name` with the approprate VPC endpoint DNS name from the Terraform outputs.  __The connection should be successful.__
```
mysql --host=${vpce_dns_name} --user=foo --password=foobarbaz djl
``` 

### Revoke access to VPCE via Security Group
7. Remove the Security Group reference for `tf_sg1` from the VPCE Security Group `tf_sg3_vpce`.  Remove it from the AWS Console or run the following...
```
terraform destroy --target aws_security_group_rule.allow_db_ingress_for_ec2_sg1
```

8. Connect via RDP to the `djl-win-server` EC2 instance again and this time confirm you are __**unable**__ to reach the database.  __**The connection should time out.**__

### Setup the IAM User in the RDS Database
9. Create the `rds_iam_user` within your Database.  For this I created a schema specifically for the user, create the user then grant privs to the schema to the user.
```
CREATE SCHEMA `rds_iam_user` ;
CREATE USER rds_iam_user IDENTIFIED WITH AWSAuthenticationPlugin AS 'RDS';
GRANT ALL ON rds_iam_user.* TO 'rds_iam_user'@'%';            
```

### Test the IAM Authentication accross the VPC Endpoint
9. Connect via RDP to the `djl-win-server2` EC2 instance.  

10. Setup the necessary credentails for the IAM user that was provisioned per the terraform script (see the output `aws_iam_key_c` and `aws_iam_secret_c`.  IAM resources are provisioned in the `./05-RDS-IAM-Auth.tf` script.).  From the Windows instance, you can open up a Command Line or PowerShell terminal and run the `aws configure` command to setup the credentails.  Enter the credential information similar to what is displayed below.
![Configure AWS IAM User Credentials](https://github.com/gravelgrinder/aws-vpc-privatelink-demo/blob/main/images/iam-configure-creds.png?raw=true)

11. Add the role ARN to the AWS Configure file.  Replace the `{AWS_Account_number}` value with the actual AWS Account Number of the owning role.  Confirm the referencing of the `source_profile` attribute.  This depends on what profile you defined in step #10, if you didn't provide a profile then you can keep the value as `default`.
```
[profile rdscrossacct]
role_arn = arn:aws:iam::{AWS_Account_Number}:role/tf_rds_iam_connect_role
source_profile = default
```

12. Generate the IAM Auth Token to the RDS Instance.  Note you must use the __**hostname endpoint**__ and must reference the assumed role profile you setup in step #11 with the `--profile` flag.
```
aws rds generate-db-auth-token `
    --hostname djl-database-1.crarldzwxu1i.us-east-1.rds.amazonaws.com `
    --port 3306 `
    --username rds_iam_user `
    --region=us-east-1 `
    --profile=rdscrossacct
```

13. Connect to the RDS instance via the IAM auth token provided in Step #12.  Replace the Host and Password parameter with your values.
  1. Command Line
```
mysql --host=${vpce_dns_names} \
      --port=3001 \
      --user=rds_iam_user \
      --password=${authToken} \
      --ssl-ca=full_path_to_ssl_certificate \
      --enable-cleartext-plugin 
```
  2. MySQL Workbench
    * ![Enable Clear Text Auth](https://github.com/gravelgrinder/aws-vpc-privatelink-demo/blob/main/images/mysql-workbench-enable-cleartext-auth.png?raw=true)
    * ![Success](https://github.com/gravelgrinder/aws-vpc-privatelink-demo/blob/main/images/mysql-workbench-success.png?raw=true)




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
AWS PrivateLink
* [Deep Dive on How to Establish Private Connectivity with AWS Private Link – AWS Online Tech Talks](https://www.youtube.com/watch?v=weN2sCKFquA)
* [AWS re:Invent 2020: VPC endpoints & PrivateLink: Optimize for security, cost & operations](https://www.youtube.com/watch?v=LNf8jjBt72Y&list=PL2yQDdvlhXf-0zqlk2CIWszLXvyxL6sHi)
* [AWS re:Invent 2018: Best Practices for AWS PrivateLink (NET301)](https://www.youtube.com/watch?v=85DbVGLXw3Y)
* [AWS lowers data processing charges for AWS PrivateLink](https://aws.amazon.com/about-aws/whats-new/2021/07/aws-lowers-data-processing-charges-aws-privatelink/)
* [Leverage AWS PrivateLink to Securely connect Amazon RDS from On-Premise](https://someshsrivastava1983.medium.com/leverage-aws-privatelink-to-securely-connect-amazon-rds-from-on-premise-9bf4bd3184b3)
* [Control access to services using endpoint policies](https://docs.aws.amazon.com/vpc/latest/privatelink/vpc-endpoints-access.html)
* [AWS Blog: Hostname-as-Target for Network Load Balancers](https://aws.amazon.com/blogs/networking-and-content-delivery/hostname-as-target-for-network-load-balancers/)
* [AWS Blog: Using AWS Lambda to enable static IP addresses for Application Load Balancers](https://aws.amazon.com/blogs/networking-and-content-delivery/using-aws-lambda-to-enable-static-ip-addresses-for-application-load-balancers/#:~:text=An%20IP%2Daddress%2Dbased%20target,create%20the%20resources%20for%20us)
* [Quotas PrivateLink](https://docs.aws.amazon.com/vpc/latest/privatelink/vpc-limits-endpoints.html)
* [Quotas for your NLB/ELB](https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-limits.html)

SalesForce
* [SFDC: Secure Cross-Cloud Integrations with Private Connect](https://help.salesforce.com/s/articleView?id=sf.private_connect_overview.htm&type=5)
* [SFDC Developer Blog: Using Private Connect to Securely Connect Salesforce and AWS](https://developer.salesforce.com/blogs/2020/10/using-private-connect-to-securely-connect-data-between-salesforce-and-aws)

Amazon Redshift
* [Announcing cross-VPC support for Amazon Redshift powered by AWS PrivateLink](https://aws.amazon.com/about-aws/whats-new/2021/04/announcing-cross-vpc-support-for-amazon-redshift-powered-by-aws-privatelink/)
* [AWS Blog: Enable private access to Amazon Redshift from your client applications in another VPC](https://aws.amazon.com/blogs/big-data/enable-private-access-to-amazon-redshift-from-your-client-applications-in-another-vpc/)

RDS Authentication
* [How do I allow users to authenticate to an Amazon RDS MySQL DB instance using their IAM credentials?](https://aws.amazon.com/premiumsupport/knowledge-center/users-connect-rds-iam/)
* [Use IAM authentication to connect with SQL Workbench/J to Amazon Aurora MySQL or Amazon RDS for MySQL](https://aws.amazon.com/blogs/database/use-iam-authentication-to-connect-with-sql-workbenchj-to-amazon-aurora-mysql-or-amazon-rds-for-mysql/)



## Questions & Comments
If you have any questions or comments on the demo please reach out to me [Devin Lewis - AWS Solutions Architect](mailto:lwdvin@amazon.com?subject=AWS%2FTerraform%20FMS%20VPC%20PrivateLink%20Demo%20%28aws-vpc-privatelink-demo%29)

Of if you would like to provide personal feedback to me please click [Here](https://feedback.aws.amazon.com/?ea=lwdvin&fn=Devin&ln=Lewis)
