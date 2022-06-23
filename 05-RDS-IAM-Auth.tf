### Resources necessary for Cross Account IAM Authentication to an RDS instance.

###############################################################################
### IAM Resources in the Service Providers account
###############################################################################
## Create IAM Policy for connecting to DB 
data "template_file" "rds_iam_policy" {
  template = "${file("IAM_policies/rds_iam_policy.json")}"

  vars = { rds_resource_arn = "arn:aws:rds-db:us-east-1:758373647921:dbuser:${aws_db_instance.mysqlrds.resource_id}/rds_iam_user"}
}

data "template_file" "rds_iam_trust_policy" {
  template = "${file("IAM_policies/rds_iam_trust_policy.json")}"

  vars = {}
}

resource "aws_iam_policy" "rds_iam_policy" {
  provider    = aws.cross-acct
  name        = "tf_rds_iam_policy"
  description = "IAM Policy to allow the rds_iam_user to connect to RDS DB."
  policy      = "${data.template_file.rds_iam_policy.rendered}"
}

resource "aws_iam_role" "rds_iam_role" {
  provider            = aws.cross-acct
  name                = "tf_rds_iam_connect_role"
  assume_role_policy  = "${data.template_file.rds_iam_trust_policy.rendered}"
  managed_policy_arns = [aws_iam_policy.rds_iam_policy.arn]
}
###############################################################################



###############################################################################
### IAM Resources in the Service Consumer account
###############################################################################
data "template_file" "rds_iam_policy_c" {
  template = "${file("IAM_policies/consumer_iam_policy.json")}"

  vars = { rds_connect_role_arn = "${aws_iam_role.rds_iam_role.arn}"}
}

resource "aws_iam_policy" "rds_iam_policy_c" {
  provider    = aws.main-acct
  name        = "tf_rds_iam_policy_c"
  description = "IAM Policy to allow the rds_iam_user to assume the role in the Service Account to connect to RDS DB."
  policy      = "${data.template_file.rds_iam_policy_c.rendered}"
}


### Create IAM User
resource "aws_iam_user" "rds_iam_user_c" {
  provider = aws.main-acct
  name     = "rds_iam_user"
}

### Attach Policy to user
resource "aws_iam_user_policy_attachment" "rds_iam_user_attachment_c" {
  provider   = aws.main-acct
  user       = aws_iam_user.rds_iam_user_c.name
  policy_arn = aws_iam_policy.rds_iam_policy_c.arn
}

resource "aws_iam_access_key" "rds_iam_user_c" {
  provider = aws.main-acct
  user     = aws_iam_user.rds_iam_user_c.name
}
###############################################################################