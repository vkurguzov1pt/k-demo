provider "aws" {
  region = "eu-central-1"
}

terraform {
  backend "s3" {
    bucket = "my-k-demo-bucket"
    key    = "vpc/vpc.tfstate"
    region = "eu-central-1"
  }
}

