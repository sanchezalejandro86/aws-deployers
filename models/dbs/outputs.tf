output "sg_id" {
  value = "${aws_security_group.mongodb.id}"
}

output "instance_id" {
  value = "${aws_instance.mongodb.*.id}"
}

output "rds_host" {
  value = "${aws_route53_record.rds.*.name}"
}

output "mongodb_host" {
  value = "${aws_route53_record.mongodb.*.name}"
}
