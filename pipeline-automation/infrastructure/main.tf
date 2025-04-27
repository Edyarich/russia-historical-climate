terraform {
  required_version = ">= 1.3"
  backend "s3" {
    bucket = "your-tfstate-bucket"
    key    = "pipeline-automation/terraform.tfstate"
    region = "eu-central-1"
  }
}

provider "aws" {
  region = var.aws_region
}

# fetch account ID for resources that need it
data "aws_caller_identity" "current" {}

#-----------------------------------------------------------------------------
# 1. NETWORKING: VPC + private subnets + NAT + QuickSight VPC connection
#-----------------------------------------------------------------------------
module "network" {
  source             = "./modules/vpc"
  vpc_id             = var.vpc_id
  availability_zones = var.availability_zones
  public_subnets     = var.public_subnets
  # quicksight security group (existing or created elsewhere)
  quicksight_sg_id   = var.quicksight_enis_sg_id
}

#-----------------------------------------------------------------------------
# 2. IAM: users, roles & inline policies (including Glue-PassRole)
#-----------------------------------------------------------------------------
module "iam" {
  source = "./modules/iam"
  user_name   = var.iam_user_name
  policies     = var.iam_managed_policies
  inline_policies = {
    GluePassRoleRedshift = file("${path.module}/modules/iam/glue_pass_role.json")
  }
}

#-----------------------------------------------------------------------------
# 3. S3: bucket + folder structure
#-----------------------------------------------------------------------------
module "s3" {
  source      = "./modules/s3"
  bucket_name = var.s3_bucket_name
}

#-----------------------------------------------------------------------------
# 4. Glue: jobs for metadata, mapping, by‐year
#-----------------------------------------------------------------------------
module "glue" {
  source            = "./modules/glue"
  temp_dir          = "s3://${var.s3_bucket_name}/temp/"
  spark_log_bucket  = var.s3_bucket_name
  scripts_s3_prefix = "scripts/"
  jobs = [
    {
      name       = "metadata_to_redshift_job"
      script_uri = "s3://${var.s3_bucket_name}/scripts/metadata_to_redshift.py"
      glue_version = "3.0"
      worker_type  = "G.1X"
      number_of_workers = 10
      default_arguments = {
        "--TempDir"                    = "s3://${var.s3_bucket_name}/temp/"
        "--enable-glue-datacatalog"    = "true"
        "--conf"                       = "spark.sql.extensions=io.delta.sql.DeltaSparkSessionExtension --conf spark.sql.catalog.spark_catalog=org.apache.spark.sql.delta.catalog.DeltaCatalog"
        # …etc…
      }
    },
    {
      name       = "map_stations_job"
      script_uri = "s3://${var.s3_bucket_name}/scripts/map_stations_glue.py"
      worker_type  = "Standard"
      number_of_workers = 2
      default_arguments = {
        "--TempDir"                     = "s3://${var.s3_bucket_name}/temp/"
        "--additional-python-modules"   = "pandas,geopandas,fiona,pyproj,shapely,rtree,s3fs"
        # …etc…
      }
      glue_version = "3.0"
    },
    {
      name       = "process_by_year_job"
      script_uri = "s3://${var.s3_bucket_name}/scripts/process_by_year.py"
      worker_type  = "G.1X"
      number_of_workers = 10
      default_arguments = {
        "--TempDir"                   = "s3://${var.s3_bucket_name}/temp/"
        "--enable-metrics"            = "true"
        "--enable-spark-ui"           = "true"
        # …etc…
      }
      glue_version = "3.0"
    },
  ]
}

#-----------------------------------------------------------------------------
# 5. Redshift Serverless: namespace + workgroup
#-----------------------------------------------------------------------------
module "redshift" {
  source           = "./modules/redshift"
  namespace_name   = "russia-climate-namespace"
  workgroup_name   = "russia-climate-workgroup"
  admin_username   = var.redshift_admin_username
  admin_password   = var.redshift_admin_password
  iam_role_arns    = [ module.iam.roles["AmazonRedshift-CommandsAccessRole-20250416T193208"].arn ]
}

#-----------------------------------------------------------------------------
# 6. QuickSight Data Source: connect to Serverless namespace via VPC
#-----------------------------------------------------------------------------
module "quicksight" {
  source                = "./modules/quicksight"
  quicksight_user       = var.quicksight_user
  quicksight_pass       = var.quicksight_pass
  vpc_connection_id     = module.network.quicksight_vpc_connection_id
  redshift_endpoint     = module.redshift.workgroup_endpoint
  redshift_database     = "ghcn-data"
  redshift_port         = 5439
}

#-----------------------------------------------------------------------------
# 7. (optional) Step Functions, Orchestrator, CI/CD, Dashboards, etc.
#-----------------------------------------------------------------------------
# module "step"         { source = "./modules/step" }
# module "orchestrator" { source = "../orchestrator" }
# module "ci_cd"        { source = "../ci-cd" }
# module "dashboards"   { source = "../dashboards" }
