provider "aws" {
  alias   = "main-acct"
  profile = "default"
  region  = "us-east-2"
}

provider "aws" {
  alias   = "cross-acct"
  profile = "cross-acct"
  region  = "us-east-2"
}

data "aws_caller_identity" "main-acct" {
  provider = aws.main-acct
}

data "template_file" "rds_policy" {
  template = "${file("createRdsPolicy.json")}"

  vars = {}
}

resource "aws_iam_policy" "rds" {
  provider = aws.cross-acct
  name     = "tf-rds-policy"
  policy   = "${data.template_file.rds_policy.rendered}"
}

data "aws_iam_policy_document" "assume_role" {
  provider = aws.cross-acct
  statement {
    actions = [
      "sts:AssumeRole",
      "sts:TagSession",
      "sts:SetSourceIdentity"
    ]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.main-acct.account_id}:user/djlsystem"]
    }
  }
}

resource "aws_iam_role" "assume_role" {
  provider            = aws.cross-acct
  name                = "djl-tf-assume_role"
  assume_role_policy  = data.aws_iam_policy_document.assume_role.json
  managed_policy_arns = [aws_iam_policy.rds.arn]
  tags                = {}
}


###REMOVE###data "aws_iam_policy_document" "assume_role_permissions" {
###REMOVE###  provider = aws.main-acct
###REMOVE###  statement {
###REMOVE###        "Effect": "Allow",
###REMOVE###        "Action": "sts:AssumeRole",
###REMOVE###        "Resource": [aws_iam_role.assume_role.arn]
###REMOVE###  }
###REMOVE###  
###REMOVE###}
###REMOVE###
###REMOVE###resource "aws_iam_user_policy" "assume_policy" {
###REMOVE###  provider = aws.main-acct
###REMOVE###  name = "tf_assume_policy"
###REMOVE###  user = "djlsystem"
###REMOVE###  policy = data.aws_iam_policy_document.assume_role_permissions.json
###REMOVE###}