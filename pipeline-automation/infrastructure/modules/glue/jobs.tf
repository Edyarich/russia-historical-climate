# Glue ETL job: convert metadata to CSV and load to Redshift-ready S3
resource "aws_glue_job" "metadata_to_redshift" {
  name     = "metadata_to_redshift_job"
  role_arn = aws_iam_role.glue_redshift.arn

  command {
    name            = "glueetl"
    python_version  = "3"
    script_location = "s3://russia-historical-climate-edyarich/scripts/metadata_to_redshift.py"
  }

  default_arguments = {
    "--TempDir"                        = "s3://russia-historical-climate-edyarich/temp/"
    "--enable-metrics"                 = "true"
    "--spark-event-logs-path"         = "s3://russia-historical-climate-edyarich/logs/spark_history_logs/"
    "--enable-job-insights"            = "true"
    "--enable-observability-metrics"   = "true"
    "--conf"                           = "spark.sql.extensions=io.delta.sql.DeltaSparkSessionExtension --conf spark.sql.catalog.spark_catalog=org.apache.spark.sql.delta.catalog.DeltaCatalog"
    "--enable-glue-datacatalog"        = "true"
    "--enable-continuous-cloudwatch-log" = "true"
    "--job-bookmark-option"            = "job-bookmark-enable"
    "--datalake-formats"               = "delta"
    "--job-language"                   = "python"
  }

  glue_version      = "3.0"
  max_retries       = 1
  max_capacity      = 2
  worker_type       = "Standard"
}

# Glue Python shell job: map stations to regions and cities
resource "aws_glue_job" "map_stations" {
  name     = "map_stations_job"
  role_arn = aws_iam_role.glue_redshift.arn

  command {
    name            = "pythonshell"
    python_version  = "3"
    script_location = "s3://russia-historical-climate-edyarich/scripts/map_stations_glue.py"
  }

  default_arguments = {
    "--TempDir"                     = "s3://russia-historical-climate-edyarich/temp/"
    "--enable-job-insights"         = "true"
    "--job-language"                = "python"
    "--additional-python-modules"   = "pandas,geopandas,fiona,pyproj,shapely,rtree,s3fs"
  }

  glue_version = "3.0"
  number_of_workers = 1
  worker_type       = "G.1X"
}

# Glue ETL job: process data by year into partitioned Parquet
resource "aws_glue_job" "process_by_year" {
  name     = "process_by_year_job"
  role_arn = aws_iam_role.glue_redshift.arn

  command {
    name            = "glueetl"
    python_version  = "3"
    script_location = "s3://russia-historical-climate-edyarich/scripts/process_by_year.py"
  }

  default_arguments = {
    "--YEAR"                          = "2025"
    "--TempDir"                       = "s3://russia-historical-climate-edyarich/temp/"
    "--enable-metrics"                = "true"
    "--enable-spark-ui"               = "true"
    "--spark-event-logs-path"         = "s3://russia-historical-climate-edyarich/logs/spark_history_logs/"
    "--enable-job-insights"           = "true"
    "--enable-observability-metrics"  = "true"
    "--enable-glue-datacatalog"       = "true"
    "--enable-continuous-cloudwatch-log" = "true"
    "--job-bookmark-option"           = "job-bookmark-enable"
    "--job-language"                  = "python"
  }

  glue_version      = "3.0"
  max_retries       = 1
  max_capacity      = 4
  worker_type       = "Standard"
}