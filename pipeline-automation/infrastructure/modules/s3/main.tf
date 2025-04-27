resource "aws_s3_bucket" "data" {
  bucket        = "russia-historical-climate-edyarich"
  acl           = "private"
  force_destroy = true
  tags = {
    Name = "russia-historical-climate-bucket"
  }
}

resource "aws_s3_bucket_object" "folders" {
  for_each = toset([
    "ghcn_data/",
    "ghcn_data/external/",
    "ghcn_data/processed/",
    "ghcn_data/processed/by_year/",
    "ghcn_data/processed/metadata/",
    "logs/",
    "logs/spark_history_logs/",
    "query_results/",
    "scripts/",
    "temp/",
  ])
  bucket  = aws_s3_bucket.data.id
  key     = each.value
  content = ""
}

locals {
  script_files = fileset("${path.module}/../../scripts", "*.py")
}

resource "aws_s3_bucket_object" "script_uploads" {
  for_each = toset(local.script_files)
  bucket   = aws_s3_bucket.data.id
  key      = "scripts/${each.value}"
  source   = "${path.module}/../../scripts/${each.value}"
}
