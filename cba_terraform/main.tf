provider "aws" {
  region = var.region
}

# To view your current region for testing different environments

data "aws_region" "current" {}



data "aws_ssm_parameter" "instance_ami" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}


resource "aws_vpc" "cba_vpc" {
    cidr_block = "10.0.0.0/16"
    enable_dns_support = "true"
    enable_dns_hostnames = "true"
    instance_tenancy = "default"

    tags= {
        Name="testApacheVPC"
    }
  
}


resource "aws_subnet" "test_cba_public" {
    vpc_id = aws_vpc.cba_vpc.id
    cidr_block = "10.0.1.0/24"
    map_public_ip_on_launch = "true"
    availability_zone = "eu-west-2a"

    tags = {
      "Name" = "testApachePublicSubnet"
    }
  
}


resource "aws_subnet" "test_cba_private" {
    vpc_id = aws_vpc.cba_vpc.id
    cidr_block = "10.0.2.0/24"
    map_public_ip_on_launch = "false"
    availability_zone = "eu-west-2a"

    tags = {
      "Name" = "testApachePrivateSubnet"
    }
  
}

resource "aws_internet_gateway" "test_cba_igw" {
    vpc_id = aws_vpc.cba_vpc.id

    tags = {
        Name = "TestAPacheIGW"
    }
  
}

resource "aws_route_table" "test_public_rt" {
    vpc_id = aws_vpc.cba_vpc.id

    route  {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.test_cba_igw.id
    }


    tags = {
      "name" = "TestApachePublicRT"
    }
  
}

resource "aws_route_table_association" "test_cba_subnet_rt_public" {
  subnet_id = aws_subnet.test_cba_public.id
  route_table_id = aws_route_table.test_public_rt.id
}

# resource "aws_security_group" "cba_tf_sg" {
#   name = "cba_tf_sg"
#   description = "allow all traffic"
#   vpc_id = aws_vpc.cba_vpc.id

  

#   ingress {
#     from_port = 22
#     to_port = 22
#     protocol = "tcp"
   
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   ingress {
#     from_port = 80
#     to_port = 80
#     protocol = "tcp"
   
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   egress {
#     from_port = 0
#     to_port = 0
#     protocol = "-1"
   
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = {
#     Name = "TestCBATerraformSG"
#   }


# }

resource "aws_security_group" "cba_tf_sg" {
  vpc_id = aws_vpc.cba_vpc.id
  name   = "cba_tf_sg"
  dynamic "ingress" {
    for_each = var.rules
    content {
      from_port   = ingress.value["port"]
      to_port     = ingress.value["port"]
      protocol    = ingress.value["protocol"]
      cidr_blocks = ingress.value["cidr_blocks"]
    }
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "ApacheSG"
  }
}



resource "aws_instance" "cba_tf_instance" {
  ami = data.aws_ssm_parameter.instance_ami.value
  instance_type = var.instance_type
  security_groups = [aws_security_group.cba_tf_sg.id]
  subnet_id = aws_subnet.test_cba_public.id
  
  key_name = var.key_name
  user_data = fileexists("install_apache.sh") ? file("install_apache.sh") : null

  tags = {
    Name = "TestApacheInstance"
  }

}