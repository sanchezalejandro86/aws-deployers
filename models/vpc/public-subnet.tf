resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true

  tags {
     Name = "${replace(var.clustername, "-", ".")}"
     env = "${var.clustername}"
  }
}

data "aws_availability_zones" "available" {}

resource "aws_subnet" "public-subnet" {
  count             = "${var.az_count}"
  vpc_id            = "${aws_vpc.main.id}"
  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
  cidr_block        = "${cidrsubnet("10.0.128.0/18", 2, count.index)}"
  map_public_ip_on_launch = true

  tags = {
    Name      = "${var.clustername}-public-subnet-${count.index}"
    env       = "${var.clustername}"
    layer     = "public"
  }
}


/*##########################################################
# Internet Gateway
# ..... Create and Route
##########################################################*/

resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.main.id}"

  tags = {
    Name      = "${var.clustername}-igw"
    env       = "${var.clustername}"
  }
}

resource "aws_route_table" "public-rt" {
  vpc_id = "${aws_vpc.main.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.igw.id}"
  }

  tags = {
    Name      = "${var.clustername}-public-rt"
    env       = "${var.clustername}"
  }

}

resource "aws_route_table_association" "public-subnets-assoc" {
  count          = "${var.az_count}"
  subnet_id      = "${element(aws_subnet.public-subnet.*.id, count.index)}"
  route_table_id = "${aws_route_table.public-rt.id}"
}

/*##########################################################
# Simple (Unsecured) Security Group
# .....
##########################################################*/

resource "aws_security_group" "ssh" {
  name        = "${var.clustername}-ssh"
  description = "Allow incoming SSH connections from anywhere"
  vpc_id      = "${aws_vpc.main.id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  tags = {
    env       = "${var.clustername}"
  }
}


resource "aws_route53_zone" "phz" {
  name = "local.${replace(var.clustername, "-", ".")}"
  comment = "Private Hosted Zone for ${aws_vpc.main.id}"

  vpc_id = "${aws_vpc.main.id}"
  force_destroy = true

  tags = {
    env = "${var.clustername}"
  }
}
