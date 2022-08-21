provider "aws" {
  region = "eu-west-2"
}

data "aws_ssm_parameter" "instance_ami" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}


#Creating VPC
resource "aws_vpc" "Terra-vpc" {
  cidr_block       = var.vpc_cidr
  instance_tenancy = "default"
  enable_dns_hostnames = "true"
  enable_dns_support = "true"

  tags = {
    Name = "Terra-vpc"
  }
}

# Creating Internet Gateway 
resource "aws_internet_gateway" "Terraform-IGW" {
  vpc_id = aws_vpc.Terra-vpc.id
}


# Creating public subnet in availability zone 1
resource "aws_subnet" "terraform_public_subnet01" {
  vpc_id                  = aws_vpc.Terra-vpc.id
  cidr_block              = var.subnet_cidr
  map_public_ip_on_launch = true
  availability_zone       = "eu-west-2a"

  tags = {
    Name = "Terraform-public-subnet01"
  }
}


# Creating public subnet in region 2
resource "aws_subnet" "terraform_public_subnet02" {
  vpc_id                  = aws_vpc.Terra-vpc.id
  cidr_block              = var.subnet1_cidr
  map_public_ip_on_launch = true
  availability_zone       = "eu-west-2b"

  tags = {
    Name = "Terraform-public-subnet02"
  }
}

#Creating Route Table
resource "aws_route_table" "route" {
  vpc_id = aws_vpc.Terra-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.Terraform-IGW.id
  }

  tags = {
    Name = "Route to internet"
  }
}

resource "aws_route_table_association" "rt1" {
  subnet_id      = aws_subnet.terraform_public_subnet01.id
  route_table_id = aws_route_table.route.id
}

resource "aws_route_table_association" "rt2" {
  subnet_id      = aws_subnet.terraform_public_subnet02.id
  route_table_id = aws_route_table.route.id
}

# Creating Security Group for ELB
resource "aws_security_group" "ELB_SG" {
  name        = "ELB Security Group"
  description = "ELB Security Group"
  vpc_id      = aws_vpc.Terra-vpc.id

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


}


# an Elastic Load Balancer
resource "aws_elb" "web_elb" {
  name = "web-elb"
  security_groups = [
    "${aws_security_group.ELB_SG.id}"
  ]
  subnets = [
    "${aws_subnet.terraform_public_subnet01.id}",
    "${aws_subnet.terraform_public_subnet02.id}"
  ]

  cross_zone_load_balancing = true

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    target              = "HTTP:80/"
  }

  listener {
    lb_port           = 80
    lb_protocol       = "http"
    instance_port     = "80"
    instance_protocol = "http"
  }

}

# Creating Launch Template
resource "aws_launch_configuration" "web" {
  name_prefix = "web-"

  image_id      = data.aws_ssm_parameter.instance_ami.value
  instance_type = var.instance_type
  key_name      = var.keyname

  security_groups             = ["${aws_security_group.ELB_SG.id}"]
  associate_public_ip_address = true
  user_data                   = file("data.sh")

  lifecycle {
    create_before_destroy = true
  }
}


#Creating Auto Scaling Group
resource "aws_autoscaling_group" "web" {
  name = "${aws_launch_configuration.web.name}-asg"

  min_size         = 3
  desired_capacity = 3
  max_size         = 3

  health_check_type = "ELB"
  load_balancers = [
    "${aws_elb.web_elb.id}"
  ]

  launch_configuration = aws_launch_configuration.web.name

  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupTotalInstances"
  ]

  metrics_granularity = "1Minute"

  vpc_zone_identifier = [
    "${aws_subnet.terraform_public_subnet01.id}",
    "${aws_subnet.terraform_public_subnet02.id}"
  ]

  # Required to redeploy without an outage.
  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "Name"
    value               = "web"
    propagate_at_launch = true
  }

}


#Creating Auto scaling group policy for scaling-up
resource "aws_autoscaling_policy" "web_policy_up" {
  name                   = "web_policy_up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.web.name
}




# Creating the Cloudwatch metric alarm for scaling-up
resource "aws_cloudwatch_metric_alarm" "web_cpu_alarm_up" {
  alarm_name          = "web_cpu_alarm_up"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "70"

  dimensions = {
    AutoScalingGroupName = "${aws_autoscaling_group.web.name}"
  }

  alarm_description = "This metric monitor EC2 instance CPU utilization"
  alarm_actions     = ["${aws_autoscaling_policy.web_policy_up.arn}"]
}


# Creating the Auto scaling policy for scaling-down
resource "aws_autoscaling_policy" "web_policy_down" {
  name                   = "web_policy_down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.web.name
}


#Creating the Cloudwatch metric alarm for scaling down
resource "aws_cloudwatch_metric_alarm" "web_cpu_alarm_down" {
  alarm_name          = "web_cpu_alarm_down"
  comparison_operator = "LessThanOrEqualToThreshold"

  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "30"

  dimensions = {
    AutoScalingGroupName = "${aws_autoscaling_group.web.name}"
  }

  alarm_description = "This metric monitor EC2 instance CPU utilization"
  alarm_actions     = ["${aws_autoscaling_policy.web_policy_down.arn}"]

}
