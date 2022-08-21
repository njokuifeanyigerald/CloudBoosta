variable "region" {
  default = "eu-west-2"
}


variable "instance_type" {
  default = "t2.micro"
}


# variable "instance_ami" {
#   default = "ami-0e34bbddc66def5ac"
# }


# variable "vpc_id" {
#   default = "vpc-0f9a20bb038753c66"
# }



variable "key_name" {
  default = "test-my-public-sg"
}


variable "rules" {
  type = list(object({
    port        = number
    protocol       = string
    cidr_blocks = list(string)
  }))
  default = [
    {
      port        = 80
      protocol       = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  },
    {
      port        = 22
      protocol       = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

