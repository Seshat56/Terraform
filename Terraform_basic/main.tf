resource "aws_vpc" "aws-vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "AWS-VPC"
  }
}

# Creating Internet Gateway 
resource "aws_internet_gateway" "demogateway" {
  vpc_id = "${aws_vpc.aws-vpc.id}"
  tags = {
    Name = "igw"
  }
}
# Creating Route Table
resource "aws_route_table" "route" {
    vpc_id = "${aws_vpc.aws-vpc.id}"

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.demogateway.id}"
    }

    tags = {
        Name = "Routetable"
    }
}
# Creating 1st web subnet 
resource "aws_subnet" "public-subnet" {
  vpc_id                  = "${aws_vpc.aws-vpc.id}"
  cidr_block             = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone = "ap-southeast-2a"

  tags = {
    Name = "subnet"
  }
}
# Associating Route Table
resource "aws_route_table_association" "rt1" {
    subnet_id = "${aws_subnet.public-subnet.id}"
    route_table_id = "${aws_route_table.route.id}"
}
# Creating Security Group 
resource "aws_security_group" "demosg" {
  vpc_id = "${aws_vpc.aws-vpc.id}"

  # Inbound Rules
  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS access from anywhere
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound Rules
  # Internet access to anywhere
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "Web-SG"
  }
}
# Creating 1st EC2 instance in Public Subnet
resource "aws_instance" "demoinstance" {
  ami                         = "ami-080660c9757080771"
  instance_type               = "t2.micro"
  // count                       = 1
  key_name                    = "new-inst"
  vpc_security_group_ids      = ["${aws_security_group.demosg.id}"]
  subnet_id                   = "${aws_subnet.public-subnet.id}"
  associate_public_ip_address = true
   user_data                  =<<-EOF
                  #!/bin/bash
                  apt update -y
                  apt install -y apache2
                  systemctl start apache2
                  systemctl enable apache2
                  EOF

  tags = {
    Name = "AWS-Instance"
  }
}
resource "aws_network_interface" "test" {
  subnet_id       = aws_subnet.public-subnet.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.demosg.id]

  attachment {
    instance     = aws_instance.demoinstance.id 
    device_index = 1
  }
  tags = {
    Name = "new-network"
  }
}
resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.web.id
  allocation_id = aws_eip.example.id
  network_interface_id = aws_network_interface.test.id
}

resource "aws_instance" "web" {
  ami               = "ami-080660c9757080771"
  availability_zone = "ap-southeast-2a"
  instance_type     = "t2.micro"

  tags = {
    Name = "Hello"
  }
}

resource "aws_eip" "example" {
  domain = "vpc"
}

resource "aws_s3_bucket" "s3_bucket" {
    
    bucket = "terra-0556"
    acl = "private"
}
resource "aws_dynamodb_table" "dynamodb-terraform-state-lock" {
  name = "terraform-state-lock-dynamo"
  hash_key = "LockID"
  read_capacity = 20
  write_capacity = 20
  attribute {
    name = "LockID"
    type = "S"
  }
}
terraform {
  backend "s3" {
    bucket = "terra-0556"
    dynamodb_table = "terraform-state-lock-dynamo"
    key    = "terraform.tfstate"
    region = "ap-southeast-2"
  }
}

