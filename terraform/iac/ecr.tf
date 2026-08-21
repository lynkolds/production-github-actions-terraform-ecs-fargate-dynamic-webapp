locals {
  # Dev-style naming: <project>-<env>-<repo>
  full_repo_name = "${var.project_name}-${var.environment}-${var.repo_name}"
}

resource "aws_ecr_repository" "ecr_repo" {
  name                 = local.full_repo_name
  image_tag_mutability = var.image_tag_mutability
  force_delete         = var.force_delete

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  tags = merge(
    {
      Name        = local.full_repo_name
      Project     = var.project_name
      Environment = var.environment
    },
    var.tags
  )
}

# Optional lifecycle policy: keep last N images
resource "aws_ecr_lifecycle_policy" "keep_last_n" {
  count      = var.enable_lifecycle_policy ? 1 : 0
  repository = aws_ecr_repository.ecr_repo.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last ${var.lifecycle_keep_last_n} images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = var.lifecycle_keep_last_n
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
