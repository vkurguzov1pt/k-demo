data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    bucket = "my-k-demo-bucket"
    key    = "vpc/vpc.tfstate"
    region = "eu-central-1"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

# Define Internet GW for public subnet
resource "aws_internet_gateway" "igw" {
  vpc_id = "${data.terraform_remote_state.vpc.outputs.vpc_id}"
  tags = {
    Name                = "k-test-igw"
    "terraform:managed" = "true"
  }
}

# Define public subnet

resource "aws_subnet" "subnets" {
  count  = "${length(data.aws_availability_zones.available.names)}"
  vpc_id            = "${data.terraform_remote_state.vpc.outputs.vpc_id}"
  cidr_block        = "10.0.${count.index+1}.0/24"
  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
  map_public_ip_on_launch = true

  tags = {
    Name                = "k-test-publicsubnet-${count.index+1}"
    "terraform:managed" = "true"
  }
}

# Define routing table for public subnet
resource "aws_route_table" "route_table" {
  vpc_id = "${data.terraform_remote_state.vpc.outputs.vpc_id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.igw.id}"
  }
  tags = {
    Name                = "k-test-rt"
    "terraform:managed" = "true"
  }
}

# Associate the routing table to public subnet
resource "aws_route_table_association" "rt-asstn" {
  count = "${length(data.aws_availability_zones.available.names)}"
  subnet_id      = "${aws_subnet.subnets[count.index].id}"
  route_table_id = "${aws_route_table.route_table.id}"
}
