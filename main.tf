provider "aws" {
 region = "eu-central-1"
}

resource "aws_instance" "my_webserver1" {
  ami                    = "ami-03a71cec707bfc3d7"
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.my_webserver1.id]
   user_data = <<EDF
#!/bin/bash
apt-get update
apt-get install -y apache2
echo "<html><body><h1>Hello, World!</h1></body></html>" > /var/www/html/index.html
systemctl restart apache2
EDF
}

resource "aws_instance" "backup_webserver" {
  ami           = "ami-03a71cec707bfc3d7"
  instance_type = "t3.micro"
}
resource "aws_elb" "webserver_elb" {
  name               = "webserver-elb"
  availability_zones = ["eu-central-1a", "eu-central-1b"]

  listener {
    instance_port     = 80
    instance_protocol = "HTTP"
    lb_port           = 80
    lb_protocol       = "HTTP"
  }

  health_check {
    target              = "HTTP:80/"
    interval            = 30
    timeout             = 5
    unhealthy_threshold = 2
    healthy_threshold   = 2
  }

  instances = [
    aws_instance.my_webserver1.id,
    aws_instance.backup_webserver.id,
  ]
}

resource "aws_security_group" "my_webserver1" {
  name = "WebServer Security Group"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}