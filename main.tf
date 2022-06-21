terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.9"
}
variable "region" {
}
variable "availability_zone" {
}
variable "ami" {
}
variable "bucket_name" {
}
variable "database_name" {
}
variable "database_user" {
}
variable "database_pass" {
}
variable "admin_user" {
}
variable "admin_pass" {
}

provider "aws" {
  region = var.region
}


resource "aws_iam_user" "s3-user" {
  name = "nc-admin"
  tags = {
    Name = "admin nextcloud"
  }
}

resource "aws_iam_access_key" "s3-user-access-key" {
  user = aws_iam_user.s3-user.name
}

resource "aws_iam_user_policy" "s3-user-policy" {
  name = "allow-full_access-s3"
  user = aws_iam_user.s3-user.name
  policy = <<-EOF
              {
                "Version": "2012-10-17",
                "Statement": [
                    {
                        "Action": [
                            "s3:*"
                        ],
                        "Effect": "Allow",
                        "Resource": "*"
                    }
                ]
              }
          EOF

}

resource "aws_s3_bucket" "nc-bucket" {
  bucket = var.bucket_name
  
  tags = {
    Name = "nextcloud bucket"
  }
}
resource "aws_s3_bucket_public_access_block" "s3-block" {
  bucket = aws_s3_bucket.nc-bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
resource "aws_vpc" "vpc" {
  cidr_block =  "10.0.0.0/16"
  tags = {
    Name = "vpc"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "gateway"
  }
}

resource "aws_nat_gateway" "nat" {
  subnet_id = aws_subnet.subnet-1.id
  allocation_id = aws_eip.eip-db.id
  tags = {
    Name = "gatewat nat"
  }
}

resource "aws_route_table" "route-table-1" {
  vpc_id = aws_vpc.vpc.id
  route  {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id  
  }
  tags = {
    Name = "route-table-1"
  }
}

resource "aws_route_table" "route-table-2" {
  vpc_id = aws_vpc.vpc.id
  route  {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
  tags = {
    Name = "route-table-2"
  }
}

resource "aws_subnet" "subnet-1" {
  map_public_ip_on_launch = true
  vpc_id = aws_vpc.vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = var.availability_zone
  tags = {
    Name = "public subnet"
  }
}
resource "aws_subnet" "subnet-2" {
  map_public_ip_on_launch = true
  vpc_id = aws_vpc.vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = var.availability_zone
  tags = {
    Name = "private subnet app-db"
  }
}

resource "aws_subnet" "subnet-3" {
  map_public_ip_on_launch = true
  vpc_id = aws_vpc.vpc.id
  cidr_block = "10.0.3.0/24"
  availability_zone = var.availability_zone
  tags = {
    Name = "private subnet db"
  }
}


resource "aws_route_table_association" "asso-route-table-1" {
  subnet_id = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.route-table-1.id
}
resource "aws_route_table_association" "asso-route-table-2" {
  subnet_id = aws_subnet.subnet-3.id
  route_table_id = aws_route_table.route-table-2.id
}

resource "aws_security_group" "sg-1" {
  name        = "allow_web_traffic"
  description = "Allow web inbound traffic"
  vpc_id = aws_vpc.vpc.id
}

resource "aws_security_group_rule" "sg-1-egress" {
  type = "egress"
  from_port = 0
  to_port = 0
  protocol = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.sg-1.id
}

resource "aws_security_group_rule" "sg-1-http" {
  type = "ingress"
  from_port = 80
  to_port = 80
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.sg-1.id
}

resource "aws_security_group_rule" "sg-1-https" {
  type = "ingress"
  from_port = 443
  to_port = 443
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.sg-1.id
}

resource "aws_security_group_rule" "sg-1-ssh" {
  type = "ingress"
  from_port = 22
  to_port = 22
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.sg-1.id
}

resource "aws_security_group" "sg-2" {
  name        = "allow_both_traffic"
  description = "Allow traffic between app and db"
  vpc_id = aws_vpc.vpc.id
}

resource "aws_security_group_rule" "sg-2-egress" {
  type = "egress"
  from_port = 0
  to_port = 0
  protocol = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.sg-2.id
}

resource "aws_security_group_rule" "sg-2-http" {
  type = "ingress"
  from_port = 80
  to_port = 80
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.sg-2.id
}

resource "aws_security_group_rule" "sg-2-https" {
  type = "ingress"
  from_port = 443
  to_port = 443
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.sg-2.id
}

resource "aws_security_group_rule" "sg-2-mariadb" {
  type = "ingress"
  from_port = 3306
  to_port = 3306
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.sg-2.id
}

resource "aws_security_group" "sg-3" {
  name        = "allow_db_traffic"
  description = "Allow db inbound traffic"
  vpc_id = aws_vpc.vpc.id
}

resource "aws_security_group_rule" "sg-3-egress" {
  type = "egress"
  from_port = 0
  to_port = 0
  protocol = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.sg-3.id
}

resource "aws_security_group_rule" "sg-3-http" {
  type = "ingress"
  from_port = 80
  to_port = 80
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.sg-3.id
}

resource "aws_security_group_rule" "sg-3-https" {
  type = "ingress"
  from_port = 443
  to_port = 443
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.sg-3.id
}

resource "aws_network_interface" "nic-1" {
  subnet_id = aws_subnet.subnet-1.id
  private_ips = ["10.0.1.50"]
  security_groups = [aws_security_group.sg-1.id]   
}
resource "aws_network_interface" "nic-2" {
  subnet_id = aws_subnet.subnet-2.id
  private_ips = ["10.0.2.50"]
  security_groups = [aws_security_group.sg-2.id]   
}
resource "aws_network_interface" "nic-3" {
  subnet_id = aws_subnet.subnet-2.id
  private_ips = ["10.0.2.51"]
  security_groups = [aws_security_group.sg-2.id]   
}
resource "aws_network_interface" "nic-4" {
  subnet_id = aws_subnet.subnet-3.id
  private_ips = ["10.0.3.50"]
  security_groups = [aws_security_group.sg-3.id]   
}

resource "aws_eip" "eip-app" {
  vpc = true
  network_interface = aws_network_interface.nic-1.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [aws_internet_gateway.gw]
  tags = {
    Name = "app wip"
  }
}

resource "aws_eip" "eip-db" {
  vpc = true
  tags = {
    Name = "db eip"
  }
}

data "template_file" "web-script" {
  template = "${file("scripts/web.sh")}"
  vars = {
    eip_ip = aws_eip.eip-app.public_ip
    region = var.region
    bucket_name = var.bucket_name
    key = aws_iam_access_key.s3-user-access-key.id
    secret = aws_iam_access_key.s3-user-access-key.secret
    database_user = var.database_user
    database_pass = var.database_pass
    database_name = var.database_name
    admin_pass = var.admin_pass
    admin_user = var.admin_user
  }
}
resource "aws_instance" "web-server-instance" {
  ami = var.ami
  instance_type = "t2.micro"
  availability_zone = var.availability_zone
  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.nic-1.id
  }
  network_interface {
    device_index = 1
    network_interface_id = aws_network_interface.nic-2.id
  }
  user_data = "${data.template_file.web-script.rendered}"
  tags = {
    Name = "app server"
  }
}

data "template_file" "db-script" {
  template = "${file("scripts/db.sh")}"
  vars = {
    database_user = var.database_user
    database_pass = var.database_pass
    database_name = var.database_name
  }
}
resource "aws_instance" "db-server-instance" {
  ami = var.ami
  instance_type = "t2.micro"
  availability_zone = var.availability_zone
  user_data = "${data.template_file.db-script.rendered}"
  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.nic-4.id
  }
  network_interface {
    device_index = 1
    network_interface_id = aws_network_interface.nic-3.id
  }
  tags = {
    Name = "database server"
  }
}

