resource "aws_iam_user" "pipeline_user" {
  name = "russia-historical-climate-iam-user"
}

# Attach managed policies
locals {
  policies = [
    "arn:aws:iam::aws:policy/AmazonDMSRedshiftS3Role",
    "arn:aws:iam::aws:policy/AmazonRedshiftFullAccess",
    "arn:aws:iam::aws:policy/AWSGlueConsoleFullAccess",
    "arn:aws:iam::aws:policy/AWSGlueServiceRole",
    "arn:aws:iam::aws:policy/AWSQuickSightAssetBundleExportPolicy",
    "arn:aws:iam::aws:policy/AWSQuickSightAssetBundleImportPolicy",
  ]
}

resource "aws_iam_user_policy_attachment" "pipeline_user_managed" {
  for_each  = toset(local.policies)
  user      = aws_iam_user.pipeline_user.name
  policy_arn = each.value
}

resource "aws_iam_user_policy" "glue_pass_role" {
  name   = "GluePassRoleRedshift"
  user   = aws_iam_user.pipeline_user.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowGluePassRole"
        Effect    = "Allow"
        Action    = "iam:PassRole"
        Resource  = "arn:aws:iam::615299755921:role/glue-redshift-role"
        Condition = {
          StringEquals = {"iam:PassedToService" = "glue.amazonaws.com"}
        }
      }
    ]
  })
}
