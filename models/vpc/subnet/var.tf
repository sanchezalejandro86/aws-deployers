variable "subnet_level" {
  type        = "string"
  description = "The subnet level identifier"
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

variable "cidr" {
  type        = "string"
  description = "Network CIDR for a VPC range"
}

variable "az_count" {
  type        = "string"
  description = "Availability Zones count"
}

variable "vpc" {
  type = "string"
  description = "The Main VPC Identifier"
}

