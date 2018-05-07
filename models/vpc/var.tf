variable "keypair" {
  type = "string"
  description = "The Keypair to use"
}

variable "ami" {
  type = "string"
  description = "The AMI to start from"
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

variable "az_count" {
  type        = "string"
  description = "Availability Zones count"
}


