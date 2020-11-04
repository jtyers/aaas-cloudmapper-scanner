data aws_ami ubuntu {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

#resource aws_launch_template scanner {
#  name          = "cloudmapper-scanner"
#  key_name      = "jonnytyers"
#  image_id      = data.aws_ami.ubuntu.id
#  instance_type = "t3a.micro"
#
#  user_data = filebase64("cloudmapper-scanner.conf")
#
#  metadata_options {
#    http_endpoint               = "enabled"
#    http_tokens                 = "required"
#    http_put_response_hop_limit = 1
#  }
#
#  network_interfaces {
#    associate_public_ip_address = true
#    delete_on_termination = true
#  }
#
#  instance_initiated_shutdown_behavior = "terminate"
#
#  instance_market_options {
#    market_type = "spot"
#  }
#
#  iam_instance_profile {
#    arn = aws_iam_instance_profile.scanner.arn
#  }
#
#}

resource aws_launch_configuration scanner {
  name_prefix   = "cloudmapper-scanner-"
  key_name      = "jonnytyers"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = "t3a.micro"

  user_data = templatefile("cloudmapper-scanner.sh", {
    queue_url                = aws_sqs_queue.queue.id,
    region                   = data.aws_region.current.name,
    bucket_name              = aws_s3_bucket.result.bucket,
    random_wait              = "",
    cloudmapper_scanner_code = filebase64(var.scanner_function_tgz),
  })

  iam_instance_profile        = aws_iam_instance_profile.scanner.name
  associate_public_ip_address = true

  lifecycle {
    create_before_destroy = true
  }
}

resource aws_autoscaling_group scanner {
  desired_capacity = 1
  min_size         = 0
  max_size         = 1

  launch_configuration = aws_launch_configuration.scanner.name

  # TODO sadly we cannot seem to tune this down to private-only subnets easily,
  # without introducing a tag (or making all subnet in the VPC private?)
  vpc_zone_identifier = [ # list of Subnet IDs
    for s in data.aws_subnet.vpc : s.id
  ]
}

resource aws_iam_instance_profile scanner {
  name = "cloudmapper-scanner"
  role = aws_iam_role.scanner.name
}
