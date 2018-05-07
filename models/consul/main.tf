# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY A CONSUL CLUSTER IN AWS
# These templates show an example of how to use the consul-cluster module to deploy Consul in AWS. We deploy two Auto
# Scaling Groups (ASGs): one with a small number of Consul server nodes and one with a larger number of Consul client
# nodes. Note that these templates assume that the AMI you provide via the ami_id input variable is built from
# the examples/consul-ami/consul.json Packer template.
# ---------------------------------------------------------------------------------------------------------------------

provider "aws" {
  region = "${var.aws_region}"
  profile = "${var.profile}"
}

# Terraform 0.9.5 suffered from https://github.com/hashicorp/terraform/issues/14399, which causes this template the
# conditionals in this template to fail.
terraform {
  required_version = ">= 0.9.3, != 0.9.5"
}

# ---------------------------------------------------------------------------------------------------------------------
# AUTOMATICALLY LOOK UP THE LATEST PRE-BUILT AMI
# This repo contains a CircleCI job that automatically builds and publishes the latest AMI by building the Packer
# template at /examples/consul-ami upon every new release. The Terraform data source below automatically looks up the
# latest AMI so that a simple "terraform apply" will just work without the user needing to manually build an AMI and
# fill in the right value.
#
# !! WARNING !! These exmaple AMIs are meant only convenience when initially testing this repo. Do NOT use these example
# AMIs in a production setting because it is important that you consciously think through the configuration you want
# in your own production AMI.
#
# NOTE: This Terraform data source must return at least one AMI result or the entire template will fail. See
# /_ci/publish-amis-in-new-account.md for more information.
# ---------------------------------------------------------------------------------------------------------------------
data "aws_ami" "consul" {
  most_recent      = true

  # If we change the AWS Account in which test are run, update this value.
  owners     = ["${var.aws_owner}"]

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "name"
    values = ["consul-ubuntu-*"]
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY THE CONSUL SERVER NODES
# ---------------------------------------------------------------------------------------------------------------------

module "consul_servers" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:hashicorp/terraform-aws-consul.git//modules/consul-cluster?ref=v0.0.1"
  source = "./modules/consul-cluster"

  cluster_name  = "consul-${var.environment}"
  cluster_size  = "${var.num_servers}"
  instance_type = "t2.micro"
  load_balancers = ["${aws_elb.consul-lb.name}"]
  
  # The EC2 Instances will use these tags to automatically discover each other and form a cluster
  cluster_tag_key   = "${var.cluster_tag_key}"
  cluster_tag_value = "${var.cluster_tag_value}"

  ami_id    = "${var.ami_id == "" ? data.aws_ami.consul.image_id : var.ami_id}"
  user_data = "${data.template_file.user_data_server.rendered}"

  vpc_id     = "${var.vpc_id}"
  subnet_ids = "${data.aws_subnet_ids.default.ids}"

  # To make testing easier, we allow Consul and SSH requests from any IP address here but in a production
  # deployment, we strongly recommend you limit this to the IP address ranges of known, trusted servers inside your VPC.
  allowed_ssh_cidr_blocks     = ["10.0.0.0/16"]
  allowed_inbound_cidr_blocks = ["10.0.0.0/16"]
  ssh_key_name                = "${var.keypair}"
}

# ---------------------------------------------------------------------------------------------------------------------
# THE USER DATA SCRIPT THAT WILL RUN ON EACH CONSUL SERVER EC2 INSTANCE WHEN IT'S BOOTING
# This script will configure and start Consul
# ---------------------------------------------------------------------------------------------------------------------

data "template_file" "user_data_server" {
  template = "${file("${path.module}/examples/root-example/user-data-server.sh")}"

  vars {
    cluster_tag_key   = "${var.cluster_tag_key}"
    cluster_tag_value = "${var.cluster_tag_value}"
  }
}

# Load Balancer
resource "aws_elb" "consul-lb" {
  name = "${var.environment}-consul-lb"

  security_groups = [
    "${module.consul_servers.consul-lb-sg}"
  ]

  subnets = ["${data.aws_subnet_ids.default.ids}"]

  listener {
    instance_port     = 8500
    instance_protocol = "http"
    lb_port           = 8500
    lb_protocol       = "http"
  }

  cross_zone_load_balancing   = true

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "TCP:8500"
    interval            = 30
  }

  tags = {
    env  = "${var.environment}"
  }
}

#resource "null_resource" "hash_ui" {
	
#  depends_on = ["aws_elb.consul-lb"]
  
#  connection {
#    host = "${var.bastion_access}"
#    user = "ec2-user"
#    private_key="${file("${path.module}/../../environments/${replace(var.environment, "-", ".")}/${var.keypair}.pem")}"
#  }

#  provisioner "remote-exec" {
#    inline = [
#      "sudo docker run -e CONSUL_ENABLE=1 -d -e CONSUL_ADDR=${aws_elb.consul-lb.dns_name}:8500 -p 8500:3000 jippi/hashi-ui",
#    ]
#  }
#}

# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY CONSUL IN THE DEFAULT VPC AND SUBNETS
# Using the default VPC and subnets makes this example easy to run and test, but it means Consul is accessible from the
# public Internet. For a production deployment, we strongly recommend deploying into a custom VPC with private subnets.
# ---------------------------------------------------------------------------------------------------------------------

data "aws_subnet_ids" "default" {
  vpc_id = "${var.vpc_id}"
  tags {
    layer = "public"
  }
}
