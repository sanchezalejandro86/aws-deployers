resource "aws_iam_role" "rds" {
    name = "${var.clustername}-rds-monitoring-role"
    assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "monitoring.rds.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "rds" {
  name = "${var.clustername}-rds-policy"
  role = "${aws_iam_role.rds.name}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "EnableCreationAndManagementOfRDSCloudwatchLogGroups",
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:PutRetentionPolicy"
            ],
            "Resource": [
                "arn:aws:logs:*:*:log-group:RDS*"
            ]
        },
        {
            "Sid": "EnableCreationAndManagementOfRDSCloudwatchLogStreams",
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "logs:PutLogEvents",
                "logs:DescribeLogStreams",
                "logs:GetLogEvents"
            ],
            "Resource": [
                "arn:aws:logs:*:*:log-group:RDS*:log-stream:*"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_policy_attachment" "rds-attach" {
    name = "${var.clustername}-enhanced-monitoring-attachment"
    roles = [
        "${aws_iam_role.rds.name}",
    ]

    policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

resource "aws_db_subnet_group" "rds" {
  name        = "${var.clustername}-main-subnet-group"
  description = "Our main group of subnets for rds"
  subnet_ids  = ["${var.subnets}"]

  tags = {
    env  = "${var.clustername}"
  }
}

resource "aws_security_group" "default" {
  name        = "${var.clustername}-main-rds-sg"
  description = "Allow all inbound traffic"
  vpc_id      = "${var.vpc}"

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "TCP"
    cidr_blocks = ["10.0.0.0/16"]
  }

#  ingress {
#    from_port   = 5432
#    to_port     = 5432
#    protocol    = "TCP"
#    cidr_blocks = ["0.0.0.0/0"]
#  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "${var.clustername}-rds-sg"
  }
}
