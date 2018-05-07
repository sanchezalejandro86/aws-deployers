
output "cluster" {
  value = "${aws_ecs_cluster.ecs.id}"
}

output "ecs-sg"{
  value = "${aws_security_group.docker_sg.id}"
}
