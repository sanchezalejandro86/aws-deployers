#DB
resource "aws_db_instance" "rds" {
  count			 = "${var.tenants}"
  identifier             = "${var.rds_identifier}-${max(count.index+1, 0)}"
  allocated_storage      = "${var.rds_storage}"
  engine                 = "${var.rds_engine}"
  engine_version         = "${lookup(var.rds_engine_version, var.rds_engine)}"
  instance_class         = "${var.rds_instance_class}"
  name                   = "${var.rds_db_name}"
  username               = "${var.rds_username}"
  password               = "${var.rds_password}"
  vpc_security_group_ids = ["${aws_security_group.default.id}"]
  db_subnet_group_name   = "${var.clustername}-main-subnet-group"
  publicly_accessible    = false
  monitoring_interval    = 60
  monitoring_role_arn    = "${aws_iam_role.rds.arn}"
  multi_az               = "${var.rds_multi_az}"
  maintenance_window     = "sun:02:30-sun:03:00"
  backup_window          =  "03:15-03:45"
  backup_retention_period = 7
  storage_type           = "gp2"
  depends_on 		 = ["aws_db_subnet_group.rds"]
}

resource "aws_route53_record" "rds" {
  count = "${var.tenants}"
  zone_id = "${var.zone}"
  name = "rds-${count.index+1}"
  type = "CNAME"
  ttl = 60
  records = ["${element(aws_db_instance.rds.*.address, count.index)}"]
}

#MONGODB
resource "aws_instance" "mongodb" {
  count		       = "${var.tenants}"
  ami                  = "${var.mongodb_ami}"
  instance_type        = "${var.mongodb_instance_type}"
  key_name             = "${var.keypair}"
  #user_data            = "${data.template_file.user_data.rendered}"
  #iam_instance_profile = "${var.mongodb_iam_name}"
  vpc_security_group_ids = ["${aws_security_group.mongodb.id}"]
  subnet_id            = "${var.subnets[0]}"
  associate_public_ip_address = false

  root_block_device {
    volume_size = 50
    volume_type = "gp2"
    delete_on_termination = false
  }

  tags {
    Name = "${var.mongodb_identifier}-${max(count.index+1, 0)}"
    env = "${var.clustername}"
  }
}

#data "template_file" "user_data" {
#  template = <<-EOF
#              	#!/bin/bash
#              	mongo wall --eval "db.createUser({user:'workia',pwd:'workia2017', roles:[{ role: 'readWrite', db: 'wall' }]});"
#              	EOF
#}

resource "aws_route53_record" "mongodb" {
  count = "${var.tenants}" 
  zone_id = "${var.zone}"
  name = "mongo-${count.index+1}"
  type = "A"
  ttl = 60
  records = ["${element(aws_instance.mongodb.*.private_ip, count.index)}"]
}
