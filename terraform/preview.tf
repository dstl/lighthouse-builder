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
        "${var.office_ip}/32", # Metal Box Factory
        "${var.client_ip}/32", # Client
        "${var.robs_ip}/32",   # Robs IP
        "172.31.0.0/16",       # Internal amazon IP range (for api/ssh access)
        "${var.jenkins_ip}/32",# External amazon IP (for jenkins access)
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
