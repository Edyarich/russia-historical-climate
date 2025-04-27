# Data lookup for the existing IAM role
data "aws_iam_role" "backfill_role" {
  name = "StepFunctions-BackfillByYear-role-1efvohich"
}

# State Machine
resource "aws_sfn_state_machine" "backfill_by_year" {
  name     = "BackfillByYear"
  role_arn = data.aws_iam_role.backfill_role.arn
  type     = "STANDARD"

  definition = <<STATE_MACHINE
{
  "Comment": "Parallel backfill of process_by_year job for years 1901–2024",
  "StartAt": "GenerateYearList",
  "States": {
    "GenerateYearList": {
      "Type": "Pass",
      "Parameters": {
        "years.$": "States.ArrayRange(1900, 2025, 1)"
      },
      "Next": "BackfillByYear"
    },
    "BackfillByYear": {
      "Type": "Map",
      "ItemsPath": "$.years",
      "MaxConcurrency": 1,
      "Parameters": {
        "year.$": "$$.Map.Item.Value"
      },
      "Iterator": {
        "StartAt": "RunGlueJob",
        "States": {
          "RunGlueJob": {
            "Type": "Task",
            "Resource": "arn:aws:states:::glue:startJobRun.sync",
            "Parameters": {
              "JobName": "process_by_year",
              "Arguments": {
                "--YEAR.$": "States.Format('{}', $.year)"
              }
            },
            "Retry": [
              {
                "ErrorEquals": [
                  "Glue.ConcurrentRunsExceededException",
                  "Glue.InternalServiceException"
                ],
                "IntervalSeconds": 30,
                "MaxAttempts": 5,
                "BackoffRate": 2
              }
            ],
            "End": true
          }
        }
      },
      "End": true
    }
  }
}
STATE_MACHINE
}
