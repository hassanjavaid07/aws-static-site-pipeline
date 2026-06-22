variable "aws_region" {
  type        = string
  description = "AWS region to deploy into"
  default     = "us-east-1"
}

variable "github_token" {
  type        = string
  description = "Secure token for GitHub authentication (used by CodeStar/GitHub source action)"
  sensitive   = true
}

variable "github_owner" {
  type        = string
  description = "GitHub repository owner/org"
  default     = "hassanjavaid07"
}

variable "github_repo" {
  type        = string
  description = "GitHub repository name"
  default     = "aws-static-site-pipeline"
}

variable "github_branch" {
  type        = string
  description = "GitHub branch to trigger the pipeline"
  default     = "main"
}

variable "senior_dev_email" {
  type        = string
  description = "Email address that receives approval notifications for promotions"
}

variable "dev_bucket_name" {
  type        = string
  description = "Globally unique S3 bucket name for the dev stage"
}

variable "stg_bucket_name" {
  type        = string
  description = "Globally unique S3 bucket name for the staging stage"
}

variable "prod_bucket_name" {
  type        = string
  description = "Globally unique S3 bucket name for the production stage (hosts the live site)"
}

variable "pipeline_artifacts_bucket_name" {
  type        = string
  description = "Globally unique S3 bucket name for CodePipeline artifacts"
}
