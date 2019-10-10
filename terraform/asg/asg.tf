data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    bucket = "my-k-demo-bucket"
    key    = "vpc/vpc.tfstate"
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

data "terraform_remote_state" "subnets" {
  backend = "s3"

  config = {
    bucket = "my-k-demo-bucket"
    key    = "subnets/subnets.tfstate"
    region = "eu-central-1"
  }
}

data "terraform_remote_state" "alb" {
  backend = "s3"

  config = {
    bucket = "my-k-demo-bucket"
    key    = "alb/alb.tfstate"
    region = "eu-central-1"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

# Define user-data file for an instance, that runs Docker
data "template_file" "user_data" {
  template = "${file("user-data.sh.tpl")}"
}

# Choose AMI for EC2 - Ubuntu 18.04
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

# Define Launch Config resource
resource "aws_launch_configuration" "lc" {
  name_prefix     = "k-demo-lc-"
  image_id        = "${data.aws_ami.ubuntu.id}"
  instance_type   = "t3.large"
  security_groups = ["${data.terraform_remote_state.sg.outputs.ec2_sg}"]
  spot_price      = "0.03"
  key_name        = "k-demo"
  enable_monitoring = false

  user_data = "${data.template_file.user_data.rendered}" 

  lifecycle {
    create_before_destroy = true
  }
}

# Define Auto Scaling Group
resource "aws_autoscaling_group" "asg" {
  name = "k-demo-asg"
  vpc_zone_identifier  = "${data.terraform_remote_state.subnets.outputs.subnet_id}"
  launch_configuration = "${aws_launch_configuration.lc.name}"
  target_group_arns = ["${data.terraform_remote_state.alb.outputs.tg_arn}"]

  desired_capacity = 3
  max_size = 5
  min_size = 1

   tag {
    key = "Name"
    propagate_at_launch = true
    value = "k-demo-example-ec2"
  }

   tag {
    key = "terraform:managed"
    propagate_at_launch = true
    value = "true"
  }
}
