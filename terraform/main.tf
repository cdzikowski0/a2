# Define VPC
resource "aws_vpc" "assesment2_vpc" {
  cidr_block           = "192.168.69.0/24"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    name = "Assessment2"
  }
}

# Define Subnets
resource "aws_subnet" "assessment2_pub_subnet" {
  vpc_id            = aws_vpc.assesment2_vpc.id
  availability_zone = "ap-south-1a"
  cidr_block        = "192.168.69.0/25"

  tags = {
    Name = "A2 Public"
  }
}

resource "aws_subnet" "assessment2_pvt_subnet" {
  vpc_id            = aws_vpc.assesment2_vpc.id
  cidr_block        = "192.168.69.128/26"
  availability_zone = "ap-south-1b"
  tags = {
    Name = "A2 Private"
  }
}

# Define Route Tables
resource "aws_route_table" "assessment2_pub_rt" {
  vpc_id = aws_vpc.assesment2_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.assessment2_igw.id
  }

  tags = {
    Name = "Assessment2 Public Route Table"
  }
}

resource "aws_route_table" "assessment2_pvt_rt" {
  vpc_id = aws_vpc.assesment2_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.assessment2_nat_gateway.id
  }

  tags = {
    Name = "Assessment2 Private Route Table"
  }
}

# Associate Route Tables with Subnets
resource "aws_route_table_association" "assessment2_pub_rt_assoc" {
  subnet_id      = aws_subnet.assessment2_pub_subnet.id
  route_table_id = aws_route_table.assessment2_pub_rt.id
}

resource "aws_route_table_association" "assessment2_pvt_rt_assoc" {
  subnet_id      = aws_subnet.assessment2_pvt_subnet.id
  route_table_id = aws_route_table.assessment2_pvt_rt.id
}

# Define security groups
resource "aws_security_group" "assessment2_public_sg" {
  name_prefix = "public_sg"
  vpc_id      = aws_vpc.assesment2_vpc.id

  ingress {
    description = "Allow HTTP traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS traffic"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow SSH traffic from public subnet"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow Postgres"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.assesment2_vpc.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "assessment2_private_sg" {
  name_prefix = "private_sg"
  vpc_id      = aws_vpc.assesment2_vpc.id

  ingress {
    description = "Allow SSH traffic from public and private subnets"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.assesment2_vpc.cidr_block]
  }

  ingress {
    description = "Allow HTTP traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS traffic"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow Postgres"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.assesment2_vpc.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
# Define Internet Gateway
resource "aws_internet_gateway" "assessment2_igw" {
  vpc_id = aws_vpc.assesment2_vpc.id

  tags = {
    Name = "Assessment2"
  }
}

# Define EIP for Nat
resource "aws_eip" "nat" {
}

# Define NAT Gateway
resource "aws_nat_gateway" "assessment2_nat_gateway" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.assessment2_pub_subnet.id
}

# Define Test EC2s

resource "aws_instance" "testWeb" {
  ami                         = "ami-0b08bfc6ff7069aff" # ap-south-1
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.assessment2_pub_subnet.id
  vpc_security_group_ids      = [aws_security_group.assessment2_public_sg.id]
  associate_public_ip_address = true
  key_name                    = var.key

}

resource "aws_instance" "testPvt" {
  ami                         = "ami-0b08bfc6ff7069aff" # ap-south-1
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.assessment2_pvt_subnet.id
  vpc_security_group_ids      = [aws_security_group.assessment2_private_sg.id]
  key_name                    = var.key
  associate_public_ip_address = false
  tags = {
    Name = "testPvt"
  }
}

# TODO ADD SUBNET GROUP to RDS