provider "aws" {
  region = "eu-west-2"
}

resource "aws_default_vpc" "default" {}

resource "aws_default_subnet" "az1" {
  availability_zone = "eu-west-2a"
}
#---------------------------------------------------
module "consulsg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.9.0"
  name = "ConsulServerSG"
  vpc_id = aws_default_vpc.default.id
  ingress_with_cidr_blocks = [
    {
      from_port   = 8500
      to_port     = 8500
      protocol    = "tcp"
      description = "Consul Internal API"
      cidr_blocks = aws_default_vpc.default.cidr_block
    },
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "SSH to ec2"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 8301
      to_port     = 8301
      protocol    = "tcp"
      description = "Consul Internal"
      cidr_blocks = aws_default_vpc.default.cidr_block
    },
    {
      from_port   = 8600
      to_port     = 8600
      protocol    = "tcp"
      description = "Consul DNS queries"
      cidr_blocks = aws_default_vpc.default.cidr_block
    },
    {
      from_port   = 8300
      to_port     = 8300
      protocol    = "tcp"
      description = "RPC"
      cidr_blocks = "0.0.0.0/0"
    }

  ]
  egress_rules = ["all-all"]
}

module "webserversg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.9.0"
  name = "WebServerSG"
  vpc_id = aws_default_vpc.default.id
  ingress_with_cidr_blocks = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "SSH to ec2"
      cidr_blocks = "0.0.0.0/0"
    },
        {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "HTTP"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 8301
      to_port     = 8301
      protocol    = "tcp"
      description = "Consul Internal"
      cidr_blocks = aws_default_vpc.default.cidr_block
    },
    {
      from_port   = 8600
      to_port     = 8600
      protocol    = "tcp"
      description = "Consul DNS queries"
      cidr_blocks = aws_default_vpc.default.cidr_block
    },
    {
      from_port   = 8300
      to_port     = 8300
      protocol    = "tcp"
      description = "RPC"
      cidr_blocks = "0.0.0.0/0"
    }

  ]
  egress_rules = ["all-all"]
}

module "ec2_instance_consul" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "4.0.0"

  for_each = toset(["A", "B"])

  name = "Consul-node-${each.key}"
  
  iam_instance_profile   = aws_iam_instance_profile.consul-join.name
  ami                    = "ami-00826bd51e68b1487"
  instance_type          = "t2.micro"
  key_name               = "ASLondonkey"
  monitoring             = true
  vpc_security_group_ids = [module.consulsg.security_group_id]
  subnet_id              = aws_default_subnet.az1.id
  user_data = <<-EOF
              #!/bin/bash
              curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
              sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
              sudo apt-get update && sudo apt-get install consul
              EOF
  
  tags = {
    ConsulServer = true
  }
}

module "ec2_webserver" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "4.0.0"

  name = "WebServer-A"
  
  iam_instance_profile   = aws_iam_instance_profile.consul-join.name
  ami                    = "ami-00826bd51e68b1487"
  instance_type          = "t2.micro"
  key_name               = "ASLondonkey"
  monitoring             = true
  vpc_security_group_ids = [module.webserversg.security_group_id]
  subnet_id              = aws_default_subnet.az1.id
  
  tags = {
    ConsulServer = true
  }
}