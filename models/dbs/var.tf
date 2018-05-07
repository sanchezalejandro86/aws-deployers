variable "subnets" {
  type        = "list"
  description = "The subnets ids"
}

variable "clustername" {
  type        = "string"
  description = "The short name of the environment that is used to define it"
}

variable "region" {
  type        = "string"
  description = "AWS Region to use"
}

variable "profile" {
  type        = "string"
  description = "AWS profile account"
}

variable "vpc" {
  type = "string"
  description = "The Main VPC Identifier"
}

variable "ecs_security_group"{
  description = "ECS Security group to access persistence layer"
}

variable "tenants" {
  description = "The tenant count to create the databases"
  default     = 1
}


# RDS VARIABLES
variable "rds_identifier" {
  description = "Identifier for your DB"
}

variable "rds_storage" {
  default     = "100"
  description = "Storage size in GB"
}

variable "rds_engine" {
  default     = "postgres"
  description = "Engine type, example values mysql, postgres"
}

variable "rds_engine_version" {
  description = "Engine version"

  default = {
    mysql    = "5.6.22"
    postgres = "9.6.3"
  }
}

variable "rds_instance_class" {
  description = "Instance class"
}

variable "rds_db_name" {
  description = "db name"
}

variable "rds_username" {
  description = "User name"
}

variable "rds_password" {
  description = "password, provide through your ENV variables"
}

variable "rds_multi_az"{
  default = "false"
  description = "Multi Available Zone for replica"
}

# MONGODB VARIABLES
variable "mongodb_identifier"       {}
variable "keypair"       {}

#variable "mongodb_basedir"          {default = "mongo"}
#variable "mongodb_conf_logpath"     {default = "mongo/logs/"}
#variable "mongodb_conf_engine"      {default = "wiredTiger"}
#variable "mongodb_conf_oplogsizemb" {default = ""}
#variable "mongodb_key_s3_object"    {}
#variable "ssl_ca_key_s3_object"     {}
#variable "ssl_agent_key_s3_object"  {}
#variable "ssl_mongod_key_s3_object" {}
#variable "opsmanager_key_s3_object" {}
#variable "mongodb_iam_name"         {}
#variable "mongodb_sg_id"            {}
#variable "subnet_id"                {}
#variable "opsmanager_subdomain"     {}
#variable "ebs_volume_id"            {}

variable "zone" {
  type = "string"
  description = "Route53 Private Hosted Zone for the VPC"
}

variable "mongodb_ami" {}
variable "mongodb_instance_type" {}

#variable "config_ephemeral" {
#  default = "true"
#}
#variable "config_ebs" {
#  default = "false"
#}

#variable "role_node" {
#  default = "false"
#}
#variable "role_opsmanager" {
#  default = "false"
#}
#variable "role_backup" {
#  default = "false"
#}
#variable "role_arbiter" {
#  default = "false"
#}
#variable "mms_group_id" {
#  default = ""
#}
#variable "mms_api_key" {
#  default = ""
#}
#variable "mms_password" {
#  default = ""
#}
