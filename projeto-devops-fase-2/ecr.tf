resource "aws_ecr_repository" "nginx-ecr" {
  name                 = "nginx-prod"
  image_tag_mutability = "MUTABLE"
}

