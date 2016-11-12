# (c) Crown Owned Copyright, 2016. Dstl.
resource "aws_security_group" "copper_lockdown" {
  name = "copper_lockdown"
  description = "Prevent egress to everywhere"

  ingress {
    from_port = 0
    to_port = 65535

    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 65535

    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "copper-jenkins" {
  ami = "${var.rhel_box}"
  instance_type = "t2.micro"
  key_name = "deploy"
  availability_zone = "${var.availability_zone}"
  security_groups = ["${aws_security_group.copper_lockdown.name}"]
  tags {
    Name = "jenkins (copper)"
  }
}

resource "aws_instance" "copper-lighthouse" {
  ami = "${var.rhel_box}"
  instance_type = "t2.micro"
  key_name = "deploy"
  availability_zone = "${var.availability_zone}"
  security_groups = ["${aws_security_group.copper_lockdown.name}"]
  tags {
    Name = "lighthouse (copper)"
  }
}

resource "aws_eip" "copper-lighthouse-public-ip" {
  instance = "${aws_instance.copper-lighthouse.id}"
}

resource "aws_eip" "copper-jenkins-public-ip" {
  instance = "${aws_instance.copper-jenkins.id}"
}

resource "aws_route53_record" "ci_copper" {
  zone_id = "${aws_route53_zone.primary.zone_id}"
  name = "ci.copper.lighthouse.pw"
  type = "A"
  ttl = "60"
  records = ["${aws_eip.copper-jenkins-public-ip.public_ip}"]
}

resource "aws_route53_record" "www_copper" {
  zone_id = "${aws_route53_zone.primary.zone_id}"
  name = "www.copper.lighthouse.pw"
  type = "A"
  ttl = "60"
  records = ["${aws_eip.copper-lighthouse-public-ip.public_ip}"]
}

output "copper_lighthouse_external_ip" {
  value = "${aws_instance.copper-lighthouse.public_ip}"
}

output "copper_lighthouse_internal_ip" {
  value = "${aws_instance.copper-lighthouse.private_ip}"
}

output "copper_jenkins_external_ip" {
  value = "${aws_instance.copper-jenkins.public_ip}"
}

output "copper_jenkins_internal_ip" {
  value = "${aws_instance.copper-jenkins.private_ip}"
}
