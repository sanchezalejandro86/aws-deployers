
provider "aws" {
  region = "${var.region}"
  profile = "${var.profile}"
}


module "broker-1" {
  region = "${var.region}"
  profile   = "${var.profile}"
  clustername = "${var.clustername}"
  subnets = "${var.subnets}"
  ami = "${var.ami}"
  instance_type = "${var.instance_type}"
  keypair = "${var.keypair}"
  security_groups = "${aws_security_group.kafka-zookeeper.id}"
  iam_instance_profile = "${aws_iam_instance_profile.kafka.name}"
  zone = "${var.zone}"
  ami_launch_index = 1
  source  = "broker"
}

module "broker-2" {
  region = "${var.region}"
  profile   = "${var.profile}"
  clustername = "${var.clustername}"
  subnets = "${var.subnets}"
  ami = "${var.ami}"
  instance_type = "${var.instance_type}"
  keypair = "${var.keypair}"
  security_groups = "${aws_security_group.kafka-zookeeper.id}"
  iam_instance_profile = "${aws_iam_instance_profile.kafka.name}"
  ami_launch_index = 2
  zone = "${var.zone}"
  source  = "broker"
}

module "broker-3" {
  region = "${var.region}"
  profile   = "${var.profile}"
  clustername = "${var.clustername}"
  subnets = "${var.subnets}"
  ami = "${var.ami}"
  instance_type = "${var.instance_type}"
  keypair = "${var.keypair}"
  security_groups = "${aws_security_group.kafka-zookeeper.id}"
  iam_instance_profile = "${aws_iam_instance_profile.kafka.name}"
  ami_launch_index = 3
  zone = "${var.zone}"
  source  = "broker"
}

resource "aws_security_group" "kafka-zookeeper" {
  name = "${var.clustername}-kafka-zookeeper-sg"
  description = "Security group for the EC2 instances to access kafka and zookeeper"
  vpc_id = "${var.vpc}"

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  # SSH from bastion
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # Zookeeper from vpc
  ingress {
    from_port   = 2181
    to_port     = 2181
    protocol    = "TCP"
    cidr_blocks = ["10.0.0.0/16"]
  }
  ingress {
    from_port   = 2888
    to_port     = 2888
    protocol    = "TCP"
    cidr_blocks = ["10.0.0.0/16"]
  }
  ingress {
    from_port   = 3888
    to_port     = 3888
    protocol    = "TCP"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # Kafka from vpc
  ingress {
    from_port   = 9092
    to_port     = 9092
    protocol    = "TCP"
    cidr_blocks = ["10.0.0.0/16"]
  }

  tags = {
    env  = "${var.clustername}"
  }
}

resource "aws_iam_instance_profile" "kafka" {
  name = "${var.clustername}-kafka-profile"
  role = "${aws_iam_role.kafka.name}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role" "kafka" {
  name = "${var.clustername}-kafka-role"

  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy" "kafka" {
  name = "${var.clustername}-kafka-permissions"
  role = "${aws_iam_role.kafka.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "cloudwatch:DescribeAlarms",
        "cloudwatch:PutMetricAlarm",
        "cloudwatch:PutMetricData",
        "cloudwatch:GetMetricStatistics",
        "cloudwatch:ListMetrics",
        "ec2:Describe*",
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams",
        "logs:PutLogEvents",
        "route53:ChangeResourceRecordSets"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

