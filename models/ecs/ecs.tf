resource "aws_ecs_cluster" "ecs" {
  name = "${var.clustername}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "consul_sg" {
  name = "${var.clustername}-discovery-sg"
  description = "Security group for the EC2 instances of the Discovery ECS cluster"
  vpc_id = "${var.vpc}"

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  ingress {
    from_port = 8300
    to_port = 8302
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  ingress {
    from_port = 8300
    to_port = 8302
    protocol = "udp"
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  ingress {
    from_port = 8400
    to_port = 8400
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  ingress {
    from_port = 8500
    to_port = 8500
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  ingress {
    from_port = 8600
    to_port = 8600
    protocol = "udp"
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  tags = {
    env  = "${var.clustername}"
  }
}

resource "aws_security_group" "docker_sg" {
  name = "${var.clustername}-docker-sg"
  description = "Security group for the EC2 instances to access docker"
  vpc_id = "${var.vpc}"

  ingress {
    from_port = 32768
    to_port = 61000
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  tags = {
    env  = "${var.clustername}"
  }
}

resource "aws_security_group" "elb_sg" {
  name = "${var.clustername}-elb-sg"
  description = "Security group for the ELBs to access EC2 instances from ECS"
  vpc_id = "${var.vpc}"
}


# Autoscaling ECS
resource "aws_autoscaling_policy" "up" {
  name                   = "${var.clustername}-policy-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = "${aws_autoscaling_group.autodiscovery.name}"
}

resource "aws_autoscaling_policy" "down" {
  name                   = "${var.clustername}-policy-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = "${aws_autoscaling_group.autodiscovery.name}"
}


resource "aws_cloudwatch_metric_alarm" "ecs_up" {
  alarm_name          = "${var.clustername}-alarm-up"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"

  dimensions {
    AutoScalingGroupName = "${aws_autoscaling_group.autodiscovery.name}"
  }

  alarm_description = "This metric monitors ec2 memory utilization up"
  alarm_actions     = ["${aws_autoscaling_policy.up.arn}"]
}

resource "aws_cloudwatch_metric_alarm" "ecs_down" {
  alarm_name          = "${var.clustername}-alarm-down"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "20"

  dimensions {
    AutoScalingGroupName = "${aws_autoscaling_group.autodiscovery.name}"
  }

  alarm_description = "This metric monitors ec2 memory utilization down"
  alarm_actions     = ["${aws_autoscaling_policy.down.arn}"]
}

resource "aws_autoscaling_group" "autodiscovery" {
  name                 = "${var.clustername}-app-asg"
  vpc_zone_identifier  = ["${var.subnets}"]
  min_size             = "${var.asg_min}"
  max_size             = "${var.asg_max}"
  desired_capacity     = "${var.asg_desired}"
  launch_configuration = "${aws_launch_configuration.autodiscovery.name}"

  tag {
    key                 = "Name"
    value               = "node-${var.clustername}"
    propagate_at_launch = true
  }
  
  tag {
    key                 = "${var.cluster_tag_key}"
    value               = "${var.cluster_tag_value}"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_launch_configuration" "autodiscovery" {
  name_prefix = "${var.clustername}-ecs-"
  image_id = "${var.ami}"
  instance_type = "${var.instance_type}"
  key_name = "${var.keypair}"
  security_groups = [
    "${aws_security_group.consul_sg.id}",
    "${aws_security_group.docker_sg.id}",
    "${aws_security_group.elb_sg.id}",
    "${var.security_group}"
  ]

  iam_instance_profile = "${aws_iam_instance_profile.autodiscovery_profile.name}"

  user_data = "${data.template_cloudinit_config.autodiscovery_cloudinit.rendered}"

  root_block_device {
    volume_type = "gp2"
    volume_size = 10
  }

  ebs_block_device {
    device_name = "/dev/xvdcz"
    volume_size = 22
    volume_type = "gp2"
  }

  lifecycle {
    create_before_destroy = true
  }

}

resource "aws_iam_instance_profile" "autodiscovery_profile" {
  name = "${var.clustername}-autodiscovery-profile"
  role = "${aws_iam_role.autodiscovery_role.name}"

  lifecycle {
    create_before_destroy = true
  }

  #provisioner "local-exec" {
  #  command = "sleep 30"
  #}
}

resource "aws_iam_role" "autodiscovery_role" {
  name = "${var.clustername}-autodiscovery-role"

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

resource "aws_iam_role_policy" "autodiscovery_permissions" {
  name = "${var.clustername}-autodiscovery-permissions"
  role = "${aws_iam_role.autodiscovery_role.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecs:CreateCluster",
        "ecs:DeregisterContainerInstance",
        "ecs:DiscoverPollEndpoint",
        "ecs:Poll",
        "ecs:RegisterContainerInstance",
        "ecs:StartTelemetrySession",
        "ecs:Submit*",
        "ecr:BatchCheckLayerAvailability",
        "ecr:BatchGetImage",
        "ecr:GetDownloadUrlForLayer",
        "ecr:GetAuthorizationToken",
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

data "template_file" "ecs_agent" {
  template = "${file("${path.module}/templates/ecs-agent.sh")}"

  vars {
    clustername = "${aws_ecs_cluster.ecs.name}"
    region = "${var.region}"
  }
}

data "template_file" "consul_agent" {
  template = "${file("${path.module}/templates/consul-client.sh")}"

  vars {
    cluster_tag_key   = "${var.cluster_tag_key}"
    cluster_tag_value = "${var.cluster_tag_value}"
  }
}

data "template_cloudinit_config" "autodiscovery_cloudinit" {
  gzip = false
  base64_encode = false

  part {
    content_type = "text/x-shellscript"
    content = "${data.template_file.ecs_agent.rendered}"
  }

  part {
    content_type = "text/x-shellscript"
    content = "${data.template_file.consul_agent.rendered}"
  }
}
