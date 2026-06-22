resource "aws_codepipeline" "pipeline" {
  name     = "static-website-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.pipeline_artifacts.id
    type     = "S3"
  }

  # -------------------------------------------------------------------------
  # Stage 1: Source — pulls the repo zip from GitHub on every push
  # -------------------------------------------------------------------------
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
        Owner      = var.github_owner
        Repo       = var.github_repo
        Branch     = var.github_branch
        OAuthToken = var.github_token
      }
    }
  }

  # -------------------------------------------------------------------------
  # Stage 2: Deploy_Dev — every commit lands here automatically, no approval
  # -------------------------------------------------------------------------
  stage {
    name = "Deploy_Dev"

    action {
      name            = "S3_Deploy_Dev"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "S3"
      input_artifacts = ["source_output"]
      version         = "1"

      configuration = {
        BucketName = aws_s3_bucket.dev.id
        Extract    = "true"
      }
    }
  }

  # -------------------------------------------------------------------------
  # Stage 3: Approve_Dev_To_Stg — senior dev gets an email, must approve
  # -------------------------------------------------------------------------
  stage {
    name = "Approve_Dev_To_Stg"

    action {
      name     = "Manual_Approval_Dev_To_Stg"
      category = "Approval"
      owner    = "AWS"
      provider = "Manual"
      version  = "1"

      configuration = {
        NotificationArn = aws_sns_topic.approval_dev_to_stg.arn
        CustomData      = "A new build has been deployed to DEV. Please review and approve promotion to STAGING."
      }
    }
  }

  # -------------------------------------------------------------------------
  # Stage 4: Deploy_Stg — re-deploys the SAME source artifact into stg
  # (promotion = pushing the identical build forward, not a new fetch)
  # -------------------------------------------------------------------------
  stage {
    name = "Deploy_Stg"

    action {
      name            = "S3_Deploy_Stg"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "S3"
      input_artifacts = ["source_output"]
      version         = "1"

      configuration = {
        BucketName = aws_s3_bucket.stg.id
        Extract    = "true"
      }
    }
  }

  # -------------------------------------------------------------------------
  # Stage 5: Approve_Stg_To_Prod — second email, gates the live release
  # -------------------------------------------------------------------------
  stage {
    name = "Approve_Stg_To_Prod"

    action {
      name     = "Manual_Approval_Stg_To_Prod"
      category = "Approval"
      owner    = "AWS"
      provider = "Manual"
      version  = "1"

      configuration = {
        NotificationArn = aws_sns_topic.approval_stg_to_prod.arn
        CustomData      = "STAGING has been reviewed. Please approve promotion to PRODUCTION (live site)."
      }
    }
  }

  # -------------------------------------------------------------------------
  # Stage 6: Deploy_Prod — final promotion, this is the live public site
  # -------------------------------------------------------------------------
  stage {
    name = "Deploy_Prod"

    action {
      name            = "S3_Deploy_Prod"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "S3"
      input_artifacts = ["source_output"]
      version         = "1"

      configuration = {
        BucketName = aws_s3_bucket.prod.id
        Extract    = "true"
      }
    }
  }
}
