variable "clustername" {
  type = "string"
  description = "The cluster name of the environment that is used to define it"
}

variable "region" {
  type = "string"
  description = "AWS Region to use"
}

variable "profile" {
  type        = "string"
  description = "AWS profile account"
}

variable "ami" {
  type = "string"
  description = "The AMI to start from"
}

variable "vpc" {
  type = "string"
  description = "The Main VPC Identifier"
}

variable "subnets" {
  type = "list"
  description = "The list of subnet the cluster will use"
}

variable "security_group" {
  type = "string"
  description = "The default SSH security Group"
}

variable "keypair" {
  type = "string"
  description = "The Keypair to use"
}

variable "zone" {
  type = "string"
  description = "Route53 Private Hosted Zone for the VPC"
}

variable "instance_type" {
  default     = "t2.small"
  description = "AWS instance type"
}

variable "asg_min" {
  description = "Min numbers of servers in ASG"
  default     = "3"
}

variable "asg_max" {
  description = "Max numbers of servers in ASG"
  default     = "3"
}

variable "asg_desired" {
  description = "Desired numbers of servers in ASG"
  default     = "3"
}


