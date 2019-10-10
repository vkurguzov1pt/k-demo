output "subnet_id" {
  value = "${aws_subnet.subnets.*.id}"
}

output "cidr_block" {
  value = "${aws_subnet.subnets.*.cidr_block}"
}
