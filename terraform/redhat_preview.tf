resource "aws_instance" "redhat-jenkins-ci" {
    ami = "${var.rhel_box}"
    instance_type = "t2.micro"
    key_name = "deploy"
    availability_zone = "${var.availability_zone}"
    security_groups = ["${aws_security_group.allow_office_ip.name}"]
    tags {
      Name = "jenkins-ci (redhat)"
    }
}

resource "aws_instance" "redhat-lighthouse-app" {
    ami = "${var.rhel_box}"
    instance_type = "t2.micro"
    key_name = "deploy"
    availability_zone = "${var.availability_zone}"
    security_groups = ["${aws_security_group.allow_office_ip.name}"]
    tags {
      Name = "lighthouse-app (redhat)"
    }
}

resource "aws_eip" "redhat-jenkins-public-ip" {
  instance = "${aws_instance.redhat-jenkins-ci.id}"
}

resource "aws_eip" "redhat-lighthouse-public-ip" {
  instance = "${aws_instance.redhat-lighthouse-app.id}"
}

resource "aws_route53_record" "ci" {
  zone_id = "${aws_route53_zone.primary.zone_id}"
  name = "ci.lighthouse.pw"
  type = "A"
  ttl = "60"
  records = ["${aws_eip.redhat-jenkins-public-ip.public_ip}"]
}

resource "aws_route53_record" "www" {
  zone_id = "${aws_route53_zone.primary.zone_id}"
  name = "www.lighthouse.pw"
  type = "A"
  ttl = "60"
  records = ["${aws_eip.redhat-lighthouse-public-ip.public_ip}"]
}

output "lighthouse_redhat_internal_ip" {
    value = "${aws_instance.redhat-lighthouse-app.private_ip}"
}

output "lighthouse_redhat_external_ip" {
    value = "${aws_instance.redhat-lighthouse-app.public_ip}"
}
