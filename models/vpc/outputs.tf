
output "vpc" {
   value = "${aws_vpc.main.id}"
}

output "public-subnets" {
  value = [ "${aws_subnet.public-subnet.*.id}" ]
}

output "ssh_security_group" {
  value = "${aws_security_group.ssh.id}"
}

output "phz_zone" {
  value = "${aws_route53_zone.phz.zone_id}"
}


output "bastion_ip" {
  value = "${aws_instance.bastion.public_ip}"
}

output "bastion_access" {
  value = "ec2-user@${aws_instance.bastion.public_ip}"
}
