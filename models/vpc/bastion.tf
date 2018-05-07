resource "aws_security_group" "web-tools" {
  name = "${var.clustername}-admin-tools-sg"
  description = "Security group for Zookeeper/Kafka/Consul Web Tools"
  vpc_id = "${aws_vpc.main.id}"

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [
      "0.0.0.0/0"]
  }
# SSH
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"]
  }
# ZooNavigator
  ingress {
    from_port = 8001
    to_port = 8001
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"]
  }
# Kafka Manager
  ingress {
    from_port = 9000
    to_port = 9000
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"]
  }
# Kafka Topics
  ingress {
    from_port = 8000
    to_port = 8000
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"]
  }
# Consul Hash UI
  ingress {
    from_port = 8500
    to_port = 8500
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"]
  }
  ingress {
    from_port = 8081
    to_port = 8081
    protocol = "tcp"
    cidr_blocks = [
      "10.0.0.0/16"]
  }
  ingress {
    from_port = 8082
    to_port = 8082
    protocol = "tcp"
    cidr_blocks = [
      "10.0.0.0/16"]
  }


  tags = {
    env  = "${var.clustername}"
  }
}

data "template_file" "init-bastion" {
  template = "${file("${path.module}/templates/init-bastion.sh")}"

  vars {
    clustername = "${var.clustername}"
  }
}


data "template_file" "kafka-manager" {
  template = "${file("${path.module}/templates/kafka-manager-docker-compose.yml")}"

  vars {
    zookeeper_cluster = "${"zookeeper1.local.${replace(var.clustername, "-", ".")}:2181,zookeeper2.local.${replace(var.clustername, "-",".")}:2181,zookeeper3.local.${replace(var.clustername, "-", ".")}:2181"}"
    #application_secret = y_esto_que_es?
  }
}

data "template_file" "kafka-topics" {
  template = "${file("${path.module}/templates/kafka-topics-ui-docker-compose.yml")}"

  vars {
    zookeeper_cluster = "${"zookeeper1.local.${replace(var.clustername, "-", ".")}:2181,zookeeper2.local.${replace(var.clustername, "-",".")}:2181,zookeeper3.local.${replace(var.clustername, "-", ".")}:2181"}"

    kafka_cluster = "${"kafka1.local.${replace(var.clustername, "-", ".")}:9092,kafka2.local.${replace(var.clustername, "-",".")}:9092,kafka3.local.${replace(var.clustername, "-", ".")}:9092"}"

    bastion_ip = "10.0.136.70"
  }
}

data "template_file" "zoonavigator" {
  template = "${file("${path.module}/templates/zoonavigator-docker-compose.yml")}"
}

resource "aws_instance" "bastion" {
  ami = "${var.ami}"
  key_name = "${var.keypair}"
  vpc_security_group_ids = ["${aws_security_group.web-tools.id}"]
  subnet_id = "${aws_subnet.public-subnet.0.id}"
  instance_type = "t2.small"
  private_ip = "10.0.136.70"

  user_data = "${data.template_file.init-bastion.rendered}"

  tags {
    Name = "${var.clustername}-bastion"
    env = "${var.clustername}"
  }

  connection {
    user = "ec2-user"
    private_key="${file("${path.module}/../../environments/${replace(var.clustername, "-", ".")}/${var.keypair}.pem")}"
  }

  provisioner "file" {
    content     = "${data.template_file.kafka-manager.rendered}"
    destination = "/tmp/kafka-manager-docker-compose.yml"
  }
  provisioner "file" {
    content     = "${data.template_file.kafka-topics.rendered}"
    destination = "/tmp/kafka-topics-ui-docker-compose.yml"
  }
  provisioner "file" {
    content     = "${data.template_file.zoonavigator.rendered}"
    destination = "/tmp/zoonavigator-docker-compose.yml"
  }

}

resource "aws_eip" "bastion" {
  vpc = true

  instance                  = "${aws_instance.bastion.id}"
  associate_with_private_ip = "10.0.136.70"
}

