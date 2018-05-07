terraform {
  backend "s3" {}
}
# VARIABLES
variable "clustername" {}
variable "region" {}
variable "profile" { default = "default" }
variable "keypair" {}

variable "amis_consul_server"{
  type = "map"

  # Workia amis generated with Consul [amazon-linux-ami]
  default = {
    "us-east-1" = "ami-755f890f"
    "us-east-2" = "ami-b5371bd0" 
  }
}

variable "amis_ecs"{
  type = "map"

  # Workia amis generated with Consul [amazon-linux-ami]
  default = {
    "us-east-1" = "ami-d65f89ac" #"ami-04351e12"
    "us-east-2" = "ami-c13519a4" #"ami-207b5a45" 
  }
}

variable "amis_kafka"{
  type = "map"

  default = {
    "us-east-1" = "ami-cd0f5cb6"
    "us-east-2" = "ami-42ecb727" 
  }
}

variable "amis_bastion"{
  type = "map"

  default = {
    "us-east-1" = "ami-a7fdcadc"
    "us-east-2" = "ami-4986a62c"
  }
}

variable "amis_mongodb"{
  type = "map"

  default = {
	"us-east-1" = "ami-b043a4ca" #"ami-fce3c696"
	"us-east-2" = "ami-1fe6c47a" #"ami-4ae2b92f"
  }
}


# MODULES
module "network" {
  clustername = "${var.clustername}"
  region    = "${var.region}"
  profile   = "${var.profile}"
  az_count  = "3"
  keypair = "${var.keypair}"
  ami = "${lookup(var.amis_bastion, var.region)}"
  source  = "models/vpc"
}

module "consul-servers" {
  num_servers = 3
  cluster_name = "consul-servers"
  aws_region = "${var.region}"
  profile   = "${var.profile}"
  environment = "${var.clustername}"
  ami_id  = "${lookup(var.amis_consul_server, var.region)}"
  cluster_tag_key = "consul-servers"
  keypair = "${var.keypair}"
  vpc_id  = "${module.network.vpc}"
  bastion_access = "${module.network.bastion_ip}"
  source  = "models/consul"
}

module "ecs" {
  clustername = "${var.clustername}"
  region = "${var.region}"
  profile   = "${var.profile}"
  keypair = "${var.keypair}"
  vpc = "${module.network.vpc}"
  zone = "${module.network.phz_zone}"
  security_group = "${module.network.ssh_security_group}"
  subnets = "${module.network.private-subnets-A}"
  ami = "${lookup(var.amis_ecs, var.region)}"
  source = "models/ecs"
}

module "kafka" {
  clustername = "${var.clustername}"
  region = "${var.region}"
  profile   = "${var.profile}"
  keypair = "${var.keypair}"
  vpc = "${module.network.vpc}"
  zone = "${module.network.phz_zone}"
  security_group = "${module.network.ssh_security_group}"
  subnets = "${module.network.private-subnets-A}"
  ami = "${lookup(var.amis_kafka, var.region)}"
  instance_type = "t2.small"
  source = "models/kafka"
}

module "dbs" {
  clustername = "${var.clustername}"
  profile   = "${var.profile}"
  region    = "${var.region}"
  vpc = "${module.network.vpc}"
  subnets = "${module.network.private-subnets-B}"
  ecs_security_group = "${module.ecs.ecs-sg}"
  zone = "${module.network.phz_zone}"
  keypair = "${var.keypair}"
  tenants = 2 #FIXME??

  #RDS	
  rds_multi_az = false
  rds_identifier="${var.clustername}-db"
  rds_storage="100" 
  rds_engine="postgres"
  rds_instance_class="db.t2.medium"
  rds_db_name="main"
  rds_username="workia"
  rds_password="workia2017"
 
  #MONGODB
  mongodb_ami = "${lookup(var.amis_mongodb, var.region)}"
  mongodb_instance_type = "t2.small"
  mongodb_identifier="${var.clustername}-mongo"
  
  source  = "models/dbs"
}

output "bastion_access" {
  value = "${module.network.bastion_access}"
}

output "consul_elb" {
  value = "${module.consul-servers.consul_servers_cluster_elb}"
}

output "ecs_cluster" {
  value = "${module.ecs.cluster}"
}

#output "kafka_elb" {
#  value = "${module.kafka.kafka_cluster_elb}"
#}

output "rds_host" {
  value = "${module.dbs.rds_host}"
}

output "mongodb_host" {
  value = "${module.dbs.mongodb_host}"
}
