# Specify the provider and access details
variable "key" {}
variable "secret" {}
variable "ami" {}

provider "aws" {
  access_key = "${var.key}"
  secret_key = "${var.secret}"
  region = "us-west-2"
}

resource "aws_elb" "web-elb" {
  name = "cmoon"

  # The same availability zone as our instances
  availability_zones = ["us-west-2a"]
  listener {
    instance_port = 80
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    target = "HTTP:80/"
    interval = 30
  }

}

resource "aws_autoscaling_group" "web-asg" {
  availability_zones = ["us-west-2a"]
  name = "cmoon"
  max_size = "1"
  min_size = "1"
  desired_capacity = "1"
  force_delete = true
  launch_configuration = "${aws_launch_configuration.web-lc.name}"
  load_balancers = ["${aws_elb.web-elb.name}"]
  #vpc_zone_identifier = ["${split(",", var.availability_zones)}"]
  tag {
    key = "Name"
    value = "web-asg"
    propagate_at_launch = "true"
  }
}

resource "aws_launch_configuration" "web-lc" {
  name = "cmoon"
  image_id = "${var.ami}"
  instance_type = "t2.micro"
  # Security group
  security_groups = ["${aws_security_group.allow_all.id}"]
  key_name = "${aws_key_pair.fakekey.key_name}"
}

resource "aws_key_pair" "fakekey" {
  key_name = "cmoon-code-key" 
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQD3F6tyPEFEzV0LX3X8BsXdMsQz1x2cEikKDEY0aIj41qgxMCP/iteneqXSIFZBp5vizPvaoIR3Um9xK7PGoW8giupGn+EPuxIA4cDM4vzOqOkiMPhz5XK0whEjkVzTo4+S0puvDZuwIsdiW9mxhJc7tgBNL0cYlWSYVkz4G/fslNfRPW5mYAM49f4fhtxPb5ok4Q2Lg9dPKVHO/Bgeu5woMc7RY0p1ej6D4CKFE6lymSDJpW0YHX/wqE9+cfEauh7xZcG0q9t2ta6F6fmX0agvpFyZo8aFbXeUBr7osSCJNgvavWbM/06niWrOvYX2xwWdhXmXSrbX8ZbabVohBK41 email@example.com"
}

# Our default security group to access
# the instances over SSH and HTTP
resource "aws_security_group" "allow_all" {

  description = "Used in the terraform"

  # SSH access from anywhere
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access from anywhere
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}