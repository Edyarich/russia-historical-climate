# QuickSight Data Source for Redshift Serverless
resource "aws_quicksight_data_source" "redshift_serverless" {
  data_source_id = "russia_climate_redshift_ds"
  name           = "russia-climate-redshift-ds"
  type           = "REDSHIFT_SERVERLESS"

  data_source_parameters {
    redshift_serverless_parameters {
      workgroup_name = aws_redshiftserverless_workgroup.russia_climate.workgroup_name
      namespace      = aws_redshiftserverless_namespace.russia_climate.namespace_name
    }
  }

  permissions {
    principal = aws_iam_role.quicksight_service.arn
    actions   = [
      "quicksight:DescribeDataSource",
      "quicksight:UpdateDataSource",
      "quicksight:DeleteDataSource",
      "quicksight:PassDataSource"
    ]
  }
}

# QuickSight Data Set
resource "aws_quicksight_data_set" "climate_dataset" {
  data_set_id   = "russia_climate_dataset"
  name          = "Russia Climate Dataset"
  import_mode   = "DIRECT_QUERY"
  physical_table_map = {
    "ClimateTable" = {
      relational_table {
        data_source_arn = aws_quicksight_data_source.redshift_serverless.arn
        catalog         = aws_redshiftserverless_namespace.russia_climate.namespace_name
        schema          = "public"
        name            = "ghcnd_daily"
      }
    }
  }

  permissions {
    principal = aws_iam_role.quicksight_service.arn
    actions   = [
      "quicksight:DescribeDataSet",
      "quicksight:UpdateDataSet",
      "quicksight:DeleteDataSet",
      "quicksight:PassDataSet"
    ]
  }
}

# QuickSight Analysis
resource "aws_quicksight_analysis" "climate_analysis" {
  analysis_id = "russia_climate_analysis"
  name        = "Russia Climate Analysis"
  data_set_arns = [aws_quicksight_data_set.climate_dataset.arn]

  permissions {
    principal = aws_iam_role.quicksight_service.arn
    actions   = [
      "quicksight:RestoreAnalysis",
      "quicksight:UpdateAnalysis",
      "quicksight:DeleteAnalysis",
      "quicksight:DescribeAnalysis",
      "quicksight:QueryAnalysis"
    ]
  }
}

# QuickSight Dashboard
resource "aws_quicksight_dashboard" "climate_dashboard" {
  dashboard_id = "russia_climate_dashboard"
  name         = "Russia Climate Dashboard"
  source_entity {
    source_analysis {
      arn             = aws_quicksight_analysis.climate_analysis.arn
      data_set_references {
        data_set_placeholder = "ClimateDataset"
        data_set_arn         = aws_quicksight_data_set.climate_dataset.arn
      }
    }
  }

  permissions {
    principal = aws_iam_role.quicksight_service.arn
    actions   = [
      "quicksight:DescribeDashboard",
      "quicksight:ListDashboardVersions",
      "quicksight:UpdateDashboard",
      "quicksight:DeleteDashboard",
      "quicksight:QueryDashboard"
    ]
  }
}