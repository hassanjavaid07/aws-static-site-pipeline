provider "aws" {
  region = "us-east-1"
}

# 1. Declare the variable at the top
variable "github_token" {
  type        = string
  description = "Secure token for GitHub authentication"
  sensitive   = true # This hides the token from printing in your terminal logs
}


# 1. S3 Bucket for Static Website Hosting
resource "aws_s3_bucket" "web_hosting" {
  bucket        = "my-unique-devops-hosting-bucket-2026" # Change to a globally unique name
  force_destroy = true
}

resource "aws_s3_bucket_website_configuration" "web_hosting_config" {
  bucket = aws_s3_bucket.web_hosting.id

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_public_access_block" "web_hosting_public" {
  bucket = aws_s3_bucket.web_hosting.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "web_hosting_policy" {
  depends_on = [aws_s3_bucket_public_access_block.web_hosting_public]
  bucket     = aws_s3_bucket.web_hosting.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.web_hosting.arn}/*"
      }
    ]
  })
}

# 2. S3 Bucket for Pipeline Artifacts
resource "aws_s3_bucket" "pipeline_artifacts" {
  bucket        = "my-unique-pipeline-artifacts-bucket-2026" # Change to a globally unique name
  force_destroy = true
}

# 3. IAM Role for CodeBuild
resource "aws_iam_role" "codebuild_role" {
  name = "codebuild-deployment-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = { Service = "codebuild.amazonaws.com" }
      }
    ]
  })
}

resource "aws_iam_role_policy" "codebuild_policy" {
  role = aws_iam_role.codebuild_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.pipeline_artifacts.arn,
          "${aws_s3_bucket.pipeline_artifacts.arn}/*",
          aws_s3_bucket.web_hosting.arn,
          "${aws_s3_bucket.web_hosting.arn}/*"
        ]
      }
    ]
  })
}

# 4. CodeBuild Project
resource "aws_codebuild_project" "site_build" {
  name          = "static-site-builder"
  build_timeout = "5"
  service_role  = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:4.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "WEB_BUCKET_NAME"
      value = aws_s3_bucket.web_hosting.id
    }
  }

  source {
    type = "CODEPIPELINE"
  }
}

# 5. IAM Role for CodePipeline
resource "aws_iam_role" "codepipeline_role" {
  name = "codepipeline-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = { Service = "codepipeline.amazonaws.com" }
      }
    ]
  })
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  role = aws_iam_role.codepipeline_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketVersioning",
          "s3:PutObject",
          "s3:PutObjectAcl"
        ]
        Resource = [
          aws_s3_bucket.pipeline_artifacts.arn,
          "${aws_s3_bucket.pipeline_artifacts.arn}/*",
          aws_s3_bucket.web_hosting.arn,          # Allows listing the hosting bucket
          "${aws_s3_bucket.web_hosting.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild"
        ]
        Resource = [aws_codebuild_project.site_build.arn]
      },
      {
        Effect = "Allow"
        Action = [
          "codestar-connections:UseConnection"
        ]
        Resource = "*"
      }
    ]
  })
}

# # 6. CodePipeline Orchestration
# resource "aws_codepipeline" "pipeline" {
#   name     = "static-website-pipeline"
#   role_arn = aws_iam_role.codepipeline_role.arn

#   artifact_store {
#     location = aws_s3_bucket.pipeline_artifacts.id
#     type     = "S3"
#   }

#   stage {
#     name = "Source"

#     action {
#       name             = "GitHub_Source"
#       category         = "Source"
#       owner            = "ThirdParty"
#       provider         = "GitHub"
#       version          = "1"
#       output_artifacts = ["source_output"]

#       configuration = {
#         Owner      = "hassanjavaid07" 
#         Repo       = "aws-static-site-pipeline"      
#         Branch     = "main"
#         OAuthToken = var.github_token
#       }
#     }
#   }

#   stage {
#     name = "Deploy"

#     action {
#       name             = "Build_And_Deploy"
#       category         = "Build"
#       owner            = "AWS"
#       provider         = "CodeBuild"
#       input_artifacts  = ["source_output"]
#       output_artifacts = ["deploy_output"]
#       version          = "1"

#       configuration = {
#         ProjectName = aws_codebuild_project.site_build.name
#       }
#     }
#   }
# }

# 6. CodePipeline Orchestration (Bypassing CodeBuild)
resource "aws_codepipeline" "pipeline" {
  name     = "static-website-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.pipeline_artifacts.id
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "GitHub_Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        Owner      = "hassanjavaid07"
        Repo       = "aws-static-site-pipeline"
        Branch     = "main"
        OAuthToken = var.github_token
      }
    }
  }

  # Replace the old "Deploy" stage with this native S3 deployment block
  stage {
    name = "Deploy"

    action {
      name            = "S3_Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "S3" # Uses native S3 integration instead of CodeBuild
      input_artifacts = ["source_output"]
      version         = "1"

      configuration = {
        BucketName = aws_s3_bucket.web_hosting.id
        Extract    = "true" # This extracts the zip file from GitHub straight into S3
      }
    }
  }
}

output "website_url" {
  value = aws_s3_bucket_website_configuration.web_hosting_config.website_endpoint
}