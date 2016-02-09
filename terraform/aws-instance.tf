provider "aws" {
    access_key = "${var.access_key}"
    secret_key = "${var.secret_key}"
    region = "${var.region}"
}

resource "aws_security_group_rule" "office-ip" {
    type = "ingress"
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    cidr_blocks = ["80.87.30.98/32"]
    security_group_id = "sg-ceda8aaa"
}

resource "aws_instance" "lighthouse-server" {
    ami = "ami-bff32ccc"
    instance_type = "t2.micro"
    key_name = "rob"
}

output "aws_instace_ip" {
    value = "${aws_instance.lighthouse-server.public_ip}"
}
