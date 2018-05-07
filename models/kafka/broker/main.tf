
provider "aws" {
  region = "${var.region}"
  profile = "${var.profile}"
}

resource "aws_autoscaling_group" "kafka" {
  name                 = "${var.clustername}-kafka-${var.ami_launch_index}"
  vpc_zone_identifier  = ["${var.subnets}"]
  min_size             = 1
  max_size             = 1
  desired_capacity     = 1
  launch_configuration = "${aws_launch_configuration.kafka.name}"

  tag {
    key                 = "Name"
    value               = "kafka-${var.clustername}-${var.ami_launch_index}"
    propagate_at_launch = true
  }
  
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_launch_configuration" "kafka" {
  name_prefix = "${var.clustername}-kafka-"
  image_id = "${var.ami}"
  instance_type = "${var.instance_type}"
  key_name = "${var.keypair}"
  security_groups = [
    "${var.security_groups}"
  ]

  iam_instance_profile = "${var.iam_instance_profile}"

  user_data = "${data.template_cloudinit_config.zookeeper-kafka.rendered}"

  root_block_device {
    volume_type = "gp2"
    volume_size = 10
  }

  ebs_block_device {
    device_name = "/dev/sdf"
    volume_size = 50
    volume_type = "gp2"
    delete_on_termination = "false"
  }

  lifecycle {
    create_before_destroy = true
  }

}

data "template_file" "setup-zookeeper" {
  template = "${file("${path.module}/templates/setup-zookeeper.sh")}"

  vars {
    clustername = "${replace(var.clustername, "-", ".")}"
    hosted_zone_id = "${var.zone}"
    ami_launch_index = "${var.ami_launch_index}"
  }
}

data "template_file" "setup-kafka-ebs" {
  template = "${file("${path.module}/templates/setup-kafka-ebs.sh")}"
}

data "template_file" "setup-kafka-single" {
  template = "${file("${path.module}/templates/setup-kafka-single.sh")}"

  vars {
    clustername = "${replace(var.clustername, "-", ".")}"
    ami_launch_index = "${var.ami_launch_index}"
  }
}

data "template_cloudinit_config" "zookeeper-kafka" {
  gzip = false
  base64_encode = false

  part {
    content_type = "text/x-shellscript"
    content = "${data.template_file.setup-zookeeper.rendered}"
  }

  part {
    content_type = "text/x-shellscript"
    content = "${data.template_file.setup-kafka-ebs.rendered}"
  }

  part {
    content_type = "text/x-shellscript"
    content = "${data.template_file.setup-kafka-single.rendered}"
  }
}

