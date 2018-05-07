provider "aws" {
  region  = "${var.region}"
  profile = "${var.profile}"
}

data "aws_availability_zones" "available" {}

resource "aws_subnet" "private-subnet" {
  count             = "${var.az_count}"
  cidr_block        = "${cidrsubnet(var.cidr, 2, count.index)}"
  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
  vpc_id            = "${var.vpc}"
  map_public_ip_on_launch = false
  
  tags = {
    Name      = "${var.clustername}-private-subnet-${var.subnet_level}-${count.index}"
    env       = "${var.clustername}"
    layer     = "${var.subnet_level}"
  }
}

output "subnets" {
  value = [ "${aws_subnet.private-subnet.*.id}" ]
}

