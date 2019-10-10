data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    bucket = "my-k-demo-bucket"
    key    = "vpc/vpc.tfstate"
    region = "eu-central-1"
  }
}

data "terraform_remote_state" "cert" {
  backend = "s3"

  config = {
    bucket = "my-k-demo-bucket"
    key    = "cert/cert.tfstate"
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


data "terraform_remote_state" "sg" {
  backend = "s3"

  config = {
    bucket = "my-k-demo-bucket"
    key    = "security-groups/sg.tfstate"
    region = "eu-central-1"
  }
}

data "aws_subnet_ids" "available" {
  vpc_id = "${data.terraform_remote_state.vpc.outputs.vpc_id}"
}

data "aws_subnet" "available" {
  count = "${length(data.aws_subnet_ids.available.ids)}"
  id    = "${tolist(data.aws_subnet_ids.available.ids)[count.index]}"
}

locals {
  internal_zone = "my-nginx.internal"
}

# Define Application Load Balancer
resource "aws_lb" "alb" {
  name               = "k-test-lb"
  load_balancer_type = "application"
  security_groups    = ["${data.terraform_remote_state.sg.outputs.alb_sg}"]
  subnets            = "${data.aws_subnet.available.*.id}"

  enable_cross_zone_load_balancing = true

  tags = {
    Name                = "k-test-alb"
    "terraform:managed" = "true"
  }
}

# Define Target Group for k-test-alb balancer
resource "aws_lb_target_group" "target_group" {
  name     = "k-test-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${data.terraform_remote_state.vpc.outputs.vpc_id}"

  stickiness {
    enabled = false
    type    = "lb_cookie"
  }

  tags = {
    Name                = "k-test-tg"
    "terraform:managed" = "true"
  }
}

# Define Listeners
resource "aws_lb_listener" "lb_listener_80" {
  load_balancer_arn = "${aws_lb.alb.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "lb_listener_443" {
  load_balancer_arn = "${aws_lb.alb.arn}"
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "${data.terraform_remote_state.cert.outputs.cert_arn}"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.target_group.arn}"
  }
}

resource "aws_lb_listener_rule" "forward_to_internal" {
  listener_arn = "${aws_lb_listener.lb_listener_443.arn}"
  action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.target_group.arn}"
  }

  condition {
    field  = "host-header"
    values = [local.internal_zone]
  }
}
