resource "aws_ecr_repository" "ecr" {
  name = "k-test-ecr"

  tags = {
    Name = "k-test-ecr"
    "terraform:managed" = "true"
  }
}
