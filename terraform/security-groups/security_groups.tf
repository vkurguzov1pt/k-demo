data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    bucket = "my-k-demo-bucket"
    key    = "vpc/vpc.tfstate"
    region = "eu-central-1"
  }
}

data "terraform_remote_state" "subnets" {
  backend = "s3"

  config = {
    bucket = "my-k-demo-bucket"
    key    = "subnets/subnets.tfstate"
    region = "eu-central-1"
  }
}

locals {
  my_ips = tolist(["${var.my_home_ip}", "${var.my_work_ip}"])
}

# Define security group for alb

resource "aws_security_group" "alb_sg" {
  name        = "alb_sg"
  description = "Sg for ALB"
  vpc_id      = "${data.terraform_remote_state.vpc.outputs.vpc_id}"

  # Allow http
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow https 
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow any outside
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name                = "k-alb-sg"
    "terraform:managed" = "true"
  }
}

# Define security group for instances

resource "aws_security_group" "sg" {
  name        = "my_sg"
  description = "Test security group for demo instances"
  vpc_id      = "${data.terraform_remote_state.vpc.outputs.vpc_id}"

  # Open SSH from home & for local
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = concat(local.my_ips, "${data.terraform_remote_state.subnets.outputs.cidr_block}")
  }

  # Open 80 from home & local 
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = concat(local.my_ips, "${data.terraform_remote_state.subnets.outputs.cidr_block}")
  }

  # Allow any trafic outside
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name                = "k-test-sg"
    "terraform:managed" = "true"
  }
}

resource "aws_security_group_rule" "open_to_alb" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.alb_sg.id}"
  security_group_id        = "${aws_security_group.sg.id}"
}
