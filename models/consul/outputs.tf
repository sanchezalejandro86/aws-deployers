output "num_servers" {
  value = "${module.consul_servers.cluster_size}"
}

output "asg_name_servers" {
  value = "${module.consul_servers.asg_name}"
}

output "launch_config_name_servers" {
  value = "${module.consul_servers.launch_config_name}"
}

output "iam_role_arn_servers" {
  value = "${module.consul_servers.iam_role_arn}"
}

output "iam_role_id_servers" {
  value = "${module.consul_servers.iam_role_id}"
}

output "security_group_id_servers" {
  value = "${module.consul_servers.security_group_id}"
}

output "aws_region" {
  value = "${var.aws_region}"
}

output "consul_servers_cluster_tag_key" {
  value = "${module.consul_servers.cluster_tag_key}"
}

output "consul_servers_cluster_tag_value" {
  value = "${module.consul_servers.cluster_tag_value}"
}

output "consul_servers_cluster_elb" {
  value = "${aws_elb.consul-lb.dns_name}"
}