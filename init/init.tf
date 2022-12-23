### This init.tf script is use to setup the Assumed role in the Service Provider account.  This allows the scripts (01-05) to 
### create the necessary resources in the second account.  If you already have assumed roles established to create resources
### in other accounts this init script might not be necessary.
provider "aws" {
  alias   = "main-acct"
  profile = "default"
  region  = "us-east-1"
}

provider "aws" {
  alias   = "cross-acct"
  profile = "cross-acct"
  region  = "us-east-1"
}

data "aws_caller_identity" "main-acct" {
  provider = aws.main-acct
}

data "template_file" "permissions_policy" {
  template = "${file("IAM_policies/permissionsPolicy.json")}"

  vars = {principal_arn = "arn:aws:iam::${data.aws_caller_identity.main-acct.account_id}:user/djlsystem"}
}

### Create a role in the Service Provider Account (cross-acct) to allow privilages to create the necessary objects for this demo.
### Warning: This role allows AdministratorAccess to the djlsystem user within my Consuming account!  This is done for simplicity 
###          of this demo.  Instead when creating a role make sure you create it with the "Least Privialges" principal.
resource "aws_iam_role" "assume_role" {
  provider            = aws.cross-acct
  name                = "djl-tf-assume_role"
  assume_role_policy  = "${data.template_file.permissions_policy.rendered}"
  managed_policy_arns = ["arn:aws:iam::aws:policy/AdministratorAccess"]
  tags                = {}
}