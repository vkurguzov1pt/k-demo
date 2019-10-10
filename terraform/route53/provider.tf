provider "aws" {
  region = "eu-central-1"
}

terraform {
  backend "s3" {
    bucket = "my-k-demo-bucket"
    key    = "route53/route53.tfstate"
    region = "eu-central-1"
  }
}

