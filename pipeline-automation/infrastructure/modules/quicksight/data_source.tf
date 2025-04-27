variable "quicksight_user" {
  description = "QuickSight DB username (must have USAGE+SELECT on ghcn-data)"
  type        = string
}
variable "quicksight_pass" {
  description = "QuickSight DB user password"
  type        = string
  sensitive   = true
}

resource "aws_quicksight_data_source" "ghcn_redshift" {
  aws_account_id = data.aws_caller_identity.current.account_id
  data_source_id = "ghcn-redshift-ds"
  name           = "GHCN-Data-Redshift"
  type           = "REDSHIFT"

  data_source_parameters {
    redshift {
      host     = aws_redshiftserverless_workgroup.russia-climate-workgroup.endpoint
      port     = 5439
      database = "ghcn-data"
    }
  }

  vpc_connection_properties {
    vpc_connection_arn = aws_quicksight_vpc_connection.russia_climate_vpc_connection.arn
  }

  credentials {
    credential_pair {
      username = var.quicksight_user
      password = var.quicksight_pass
    }
  }
}
