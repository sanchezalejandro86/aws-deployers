variable "shortname" {
  type        = "string"
  description = "The short name of the environment that is used to define it"
}

variable "region" {
  type        = "string"
  description = "AWS Region to use"
}

resource "aws_s3_bucket" "terraform" {
  bucket = "${var.shortname}"
  acl    = "private"

  versioning {
    enabled = true
  }

  force_destroy = "false"
}

output "terraform_bucket" {
   value = "${aws_s3_bucket.terraform.bucket}"
}

