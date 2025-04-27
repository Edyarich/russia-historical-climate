# Redshift Serverless Namespace
resource "aws_redshiftserverless_namespace" "russia_climate" {
  namespace_name      = "russia-climate-namespace"
  admin_username      = "admin"
  admin_user_password = "qwerty123"

  # Grant this namespace permission to invoke Glue and access S3
  iam_roles           = [
    "arn:aws:iam::615299755921:role/AmazonRedshift-CommandsAccessRole-20250416T193208"
  ]

  tags = {
    Environment = "production"
    Project     = "russia-historical-climate"
  }
}

# Redshift Serverless Workgroup
resource "aws_redshiftserverless_workgroup" "russia_climate" {
  workgroup_name       = "russia-climate-workgroup"
  namespace_name       = aws_redshiftserverless_namespace.russia_climate.namespace_name
  base_capacity        = 32
  enhanced_vpc_routing = true
  publicly_accessible  = false

  # Optional: supply VPC configuration
  # subnet_ids         = var.subnet_ids
  # security_group_ids = var.security_group_ids

  tags = {
    Environment = "production"
    Project     = "russia-historical-climate"
  }
}