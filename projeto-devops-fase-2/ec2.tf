resource "aws_instance" "nginx-ec2" {
  ami                    = "ami-00ca32bbc84273381"
  instance_type          = "t3.micro"
  key_name               = "nginx"
  vpc_security_group_ids = [aws_security_group.nginx-sg.id]
  iam_instance_profile   = "nginx-ecr-ec2"

  tags = {
    Name        = "nginx-ec2"
    Provisioned = "Terraform"
    Cliente     = "Igor"
  }
}

resource "aws_security_group" "nginx-sg" {
  name   = "nginx-sg"
  vpc_id = data.aws_vpc.default.id
  tags = {
    Name        = "nginx-sg"
    Provisioned = "Terraform"
    Cliente     = "Igor"
  }
}

resource "aws_vpc_security_group_ingress_rule" "nginx-ssh" {
  security_group_id = aws_security_group.nginx-sg.id
  cidr_ipv4         = "187.3.29.147/32"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "nginx-http" {
  security_group_id = aws_security_group.nginx-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "nginx-https" {
  security_group_id = aws_security_group.nginx-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "nginx-outbound" {
  security_group_id = aws_security_group.nginx-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = -1
}