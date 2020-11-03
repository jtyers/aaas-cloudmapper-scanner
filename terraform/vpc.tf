data aws_vpc vpc {
  # piggyback on existing VPC so our traffic exits from the same public NAT IP
  id = "vpc-0baa48eb9272a5de2" # prowler-scanner VPC
}

data aws_subnet_ids vpc {
  vpc_id = "vpc-0baa48eb9272a5de2" # prowler-scanner VPC
}

data aws_subnet vpc {
  for_each = data.aws_subnet_ids.vpc.ids
  id       = each.value
}

resource aws_security_group sg {
  name        = "cloudmapper-scanner"
  description = "Allow outbound traffic"
  vpc_id      = data.aws_vpc.vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "cloudmapper-scanner"
  }
}
