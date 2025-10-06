terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws"{
    region = var.aws_region
    profile = var.aws_profile
    
}

# main vpc for practicheck

resource "aws_vpc" "practicheck_vpc" {
  cidr_block = var.vpc_cidr
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "practicheck_vpc"
  }
}

# internet gateway for vpc

resource "aws_internet_gateway" "practicheck_igw" {
    vpc_id = aws_vpc.practicheck_vpc.id
    tags = {
        Name = "practicheck_igw"
    }
}



# public subnet 1
resource "aws_subnet" "practicheck_public_subnet_1" {
    vpc_id = aws_vpc.practicheck_vpc.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "${var.aws_region}a"
    map_public_ip_on_launch = true

    tags = {
        Name = "practicheck_public_subnet_1"
    }
}

# private subnet 1
resource "aws_subnet" "practicheck_private_subnet_1" {
    vpc_id = aws_vpc.practicheck_vpc.id
    cidr_block = "10.0.2.0/24"
    availability_zone = "${var.aws_region}a"
    map_public_ip_on_launch = true

    tags = {
        Name = "practicheck_private_subnet_1"
    }
}

# Public RT (Internet access via IGW)
resource "aws_route_table" "practicheck_public_rt" {
  vpc_id = aws_vpc.practicheck_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.practicheck_igw.id
  }
  tags = {
    Name = "practicheck_public_rt"
  }
}
# associate public subnet with public rt
resource "aws_route_table_association" "practicheck_public_rt_association" {
  subnet_id      = aws_subnet.practicheck_public_subnet_1.id
  route_table_id = aws_route_table.practicheck_public_rt.id
  
}

# private rt (no internet access)
resource "aws_route_table" "practicheck_private_rt" {
    vpc_id = aws_vpc.practicheck_vpc.id
    tags = {
        Name = "practicheck_private_rt"
    }
}

# associate private subnet with private rt
resource "aws_route_table_association" "practicheck_private_rt_association" {
    subnet_id      = aws_subnet.practicheck_private_subnet_1.id
    route_table_id = aws_route_table.practicheck_private_rt.id
}


# security group for ec2 instances 
resource "aws_security_group" "practicheck_sg" {
    name = "practicheck_sg"
    description = "Security group for practicheck ec2 instances"
    vpc_id = aws_vpc.practicheck_vpc.id
    # ssh
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "Allow SSH from anywhere"
    }
    # http
    ingress {
        description = "HTTP"
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        
    }
    # HTTPS
    ingress {
        description = "HTTPS"
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }


    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        description = "Allow all outbound traffic"
    }

    tags = {
        Name = "practicheck_sg"
    }
}

# ec2 instance in public subnet
resource "aws_instance" "practicheck_ec2" {
    ami = var.aws_ami
    instance_type = var.instance_type
    subnet_id = aws_subnet.practicheck_public_subnet_1.id
    key_name = var.key_name
    vpc_security_group_ids = [aws_security_group.practicheck_sg.id]
}

# ebs volume    
resource "aws_ebs_volume" "practicheck_ebs" {
    availability_zone = "${var.aws_region}a"
    size = 10 #in GB
    type = "gp3"
    encrypted = true

    tags = {
        Name = "practicheck_ebs"
    }
}

# attach ebs volume to ec2 instance
resource "aws_volume_attachment" "practicheck_ebs_attachment" {
    device_name = "/dev/xvdf"
    volume_id = aws_ebs_volume.practicheck_ebs.id
    instance_id = aws_instance.practicheck_ec2.id
    force_detach = true

}

# # -------------------------------
# # Database Security Group (Private)
# # -------------------------------
# resource "aws_security_group" "db_sg" {
#   vpc_id = aws_vpc.main.id
#   name   = "Database Security Group"

#   # PostgreSQL example
#   # Custom DB port example (replace 5555 with yours)
#   ingress {
#     description     = "Custom DB Port from Web SG"
#     from_port       = 5555
#     to_port         = 5555
#     protocol        = "tcp"
#     security_groups = aws_security_group. # allow only from app/web servers
#   }
#   # Outbound (usually allow all, DB will reach out for updates/backups)
#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = {
#     Name = "Database Security Group"
#   }
# }