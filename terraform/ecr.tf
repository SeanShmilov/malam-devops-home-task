resource "aws_ecr_repository" "demoapp" {
  name                 = "demoapp"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_lifecycle_policy" "demoapp" {
  repository = aws_ecr_repository.demoapp.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Retain only the last 15 container images to optimize storage costs"
        selection = {
          tagStatus   = "any"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 30
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}


