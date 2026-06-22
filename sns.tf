# ---------------------------------------------------------------------------
# Approval gate #1: DEV -> STG
# ---------------------------------------------------------------------------
resource "aws_sns_topic" "approval_dev_to_stg" {
  name = "dev-to-stg-approval-notifications"
}

resource "aws_sns_topic_subscription" "senior_dev_dev_to_stg" {
  topic_arn = aws_sns_topic.approval_dev_to_stg.arn
  protocol  = "email"
  endpoint  = var.senior_dev_email
}

# ---------------------------------------------------------------------------
# Approval gate #2: STG -> PROD
# ---------------------------------------------------------------------------
resource "aws_sns_topic" "approval_stg_to_prod" {
  name = "stg-to-prod-approval-notifications"
}

resource "aws_sns_topic_subscription" "senior_dev_stg_to_prod" {
  topic_arn = aws_sns_topic.approval_stg_to_prod.arn
  protocol  = "email"
  endpoint  = var.senior_dev_email
}
