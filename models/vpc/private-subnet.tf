
module "private-subnet-A" {
  region = "${var.region}"
  profile   = "${var.profile}"
  cidr = "10.0.0.0/17"
  az_count  = "${var.az_count}"
  subnet_level = "A"
  clustername = "${var.clustername}"
  vpc = "${aws_vpc.main.id}"
  source  = "subnet"
}


output "private-subnets-A" {
  value = "${module.private-subnet-A.subnets}"
}

module "private-subnet-B" {
  region = "${var.region}"
  profile   = "${var.profile}"
  cidr = "10.0.192.0/19"
  az_count  = "${var.az_count}"
  subnet_level = "B"
  clustername = "${var.clustername}"
  vpc = "${aws_vpc.main.id}"
  source  = "subnet"
}

output "private-subnets-B" {
  value = "${module.private-subnet-B.subnets}"
}

/*##########################################################
# NAT Gateway
# ..... Create and Route
##########################################################*/

resource "aws_eip" "natgw-a" {
  vpc = true
}

resource "aws_nat_gateway" "natgw-a" {
  allocation_id = "${aws_eip.natgw-a.id}"
  subnet_id     = "${aws_subnet.public-subnet.0.id}"
  depends_on    = ["aws_internet_gateway.igw"]
}

resource "aws_route_table" "private-rt" {
  vpc_id = "${aws_vpc.main.id}"

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.natgw-a.id}"
  }

  tags = {
    Name      = "${var.clustername}-private-rt"
    env       = "${var.clustername}"
  }
}

resource "aws_route_table_association" "private-subnets-assoc" {
  count          = "${var.az_count}"
  subnet_id      = "${element(module.private-subnet-A.subnets, count.index)}"
  route_table_id = "${aws_route_table.private-rt.id}"
}

