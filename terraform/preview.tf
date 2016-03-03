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
        "80.87.30.98/32",
        "146.80.161.125/32",
        "172.31.0.0/16",
        "52.48.28.61/0"
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

resource "aws_instance" "lighthouse-app" {
    ami = "ami-33734044"
    instance_type = "t2.micro"
    key_name = "deploy"
    availability_zone = "${var.availability_zone}"
    security_groups = ["${aws_security_group.allow_office_ip.name}"]
    tags {
      Name = "lighthouse-app"
    }
}

resource "aws_eip" "lighthouse-public-ip" {
  instance = "${aws_instance.lighthouse-app.id}"
}

resource "aws_route53_zone" "primary" {
  name = "lighthouse.pw"
}

resource "aws_route53_record" "www" {
  zone_id = "${aws_route53_zone.primary.zone_id}"
  name = "www.lighthouse.pw"
  type = "A"
  ttl = "60"
  records = ["${aws_eip.lighthouse-public-ip.public_ip}"]
}

output "internal_ip" {
    value = "${aws_instance.lighthouse-app.private_ip}"
}

output "external_ip" {
    value = "${aws_instance.lighthouse-app.public_ip}"
}