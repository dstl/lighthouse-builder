provider "aws" {
    access_key = "${var.access_key}"
    secret_key = "${var.secret_key}"
    region = "${var.region}"
}

resource "aws_security_group" "allow_office_ip" {
  name = "allow_office_ip"
  description = "Allow all inbound traffic from Metal box factory"

  # Full ingress from the Office
  ingress {
      from_port = 0
      to_port = 65535
      protocol = "tcp"
      cidr_blocks = [
        "${var.office_ip}/32",
        "${var.client_ip}/32",
        "${var.robs_ip}/32",
        "${var.amazon_internal_ip_range}/16",
        "${var.jenkins_ip}/32",
        "${var.github_ip}/22"
      ]
  }
  # Full internet access
  egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_route53_zone" "primary" {
  name = "lighthouse.pw"
}
