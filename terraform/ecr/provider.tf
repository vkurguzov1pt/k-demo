provider "aws" {
  region = "eu-central-1"
}

terraform {
  backend "s3" {
    bucket = "my-k-demo-bucket"
    key    = "ecr/ecr.tfstate"
    region = "eu-central-1"
  }
}

