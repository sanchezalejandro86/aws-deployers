
resource "aws_security_group" "mongodb" {
  name = "${var.clustername}-main-mongodb-sg"
  description = "mongodb"
  vpc_id = "${var.vpc}"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    from_port = 27000
    to_port = 28000
    protocol = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # OpsManager non-SSL
  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    from_port = "0"
    to_port = "65535"
    protocol = "tcp"
    self = true
  }

  ingress {
    from_port = "0"
    to_port = "65535"
    protocol = "udp"
    self = true
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
