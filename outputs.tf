output "website_url" {
  description = "Public website endpoint for the production bucket"
  value       = aws_s3_bucket_website_configuration.prod_website.website_endpoint
}

output "dev_bucket_name" {
  value = aws_s3_bucket.dev.id
}

output "stg_bucket_name" {
  value = aws_s3_bucket.stg.id
}

output "prod_bucket_name" {
  value = aws_s3_bucket.prod.id
}

output "pipeline_name" {
  value = aws_codepipeline.pipeline.name
}

output "approval_topic_dev_to_stg_arn" {
  value = aws_sns_topic.approval_dev_to_stg.arn
}

output "approval_topic_stg_to_prod_arn" {
  value = aws_sns_topic.approval_stg_to_prod.arn
}
