data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    bucket = "my-k-demo-bucket"
    key    = "vpc/vpc.tfstate"
    region = "eu-central-1"
  }
}

locals {
  my_domain = "my-nginx.internal"
}

# Define Route 53 zone
resource "aws_route53_zone" "private" {
  name = local.my_domain

  vpc {
    vpc_id = "${data.terraform_remote_state.vpc.outputs.vpc_id}"
  }

  force_destroy = true

  tags = {
    Name                = "k-test-private-zone"
    "terraform:managed" = "true"
  }
}
