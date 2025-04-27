# Example for glue-redshift-role
resource "aws_iam_role" "glue_redshift" {
  name = "glue-redshift-role"
  assume_role_policy = data.aws_iam_policy_document.glue_assume.json
}

data "aws_iam_policy_document" "glue_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["glue.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

# Attach managed policies
locals {
  glue_redshift_policies = [
    "arn:aws:iam::aws:policy/AmazonRedshiftAllCommandsFullAccess",
    "arn:aws:iam::aws:policy/AmazonRedshiftFullAccess",
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
    "arn:aws:iam::aws:policy/AWSGlueConsoleFullAccess",
    "arn:aws:iam::aws:policy/AWSGlueServiceRole",
    "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess",
    "arn:aws:iam::aws:policy/SecretsManagerReadWrite",
  ]
}

resource "aws_iam_role_policy_attachment" "glue_redshift_managed" {
  for_each   = toset(local.glue_redshift_policies)
  role       = aws_iam_role.glue_redshift.name
  policy_arn = each.value
}