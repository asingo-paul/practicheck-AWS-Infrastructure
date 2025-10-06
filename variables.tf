variable "aws_region" {
    description = "This is the aws region to deploy all of the resources"
    type = string
    default = "ap-south-1"
  
}

variable "aws_profile" {
    description = "value of the aws profile"
    type = string
    default = "default"

}

# ec2 key pair
variable "key_name" {
    description = "Name of the existing key pair"
    type = string
    default = "practicheck"
}

#Vpc 
variable "vpc_cidr" {
    description = "CIDR block for the VPC"
    type = string
    default = "10.0.0.0/16"
}

variable "instance_type" {
    description = "EC2 instance type"
    type = string
    default = "t2.micro"
}

variable "aws_ami" {
    description = "AMI ID for the EC2 instance"
    type = string
    default = "ami-02d26659fd82cf299"  # ubuntu linux in ap-south-1
}

