terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "ap-south-1"
}

# resource "aws_instance" "ads-instance-web-2" {
#   ami           = "ami-0f58b397bc5c1f2e8"
#   instance_type = "t2.micro"
#   key_name = "demo-linux-1234567"
#   tags = {
#     Name = "machine-2"
#   }
# }

# resource "aws_instance" "web-12443" {
#   ami           = "ami-0f58b397bc5c1f2e8"
#   instance_type = "t2.micro"

#   tags = {
#     Name = "machine-1"
#   }
# }

# resource "aws_eip" "lb" {
#   instance = aws_instance.web-12443.id
# }



#creating the vpc

resource "aws_vpc" "webapp-vpc" {
  cidr_block = "10.10.0.0/16"

  tags = {
    Name = "Webapp-VPC"
  }
}

# creating the subnets

resource "aws_subnet" "webapp-subnet-1a" {
  vpc_id     = aws_vpc.webapp-vpc.id
  cidr_block = "10.10.0.0/24"
  availability_zone = "ap-south-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "webapp-subnet-1a"
  }
}


resource "aws_subnet" "webapp-subnet-1b" {
  vpc_id     = aws_vpc.webapp-vpc.id
  cidr_block = "10.10.1.0/24"
  availability_zone = "ap-south-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "webapp-subnet-1b"
  }
}


resource "aws_subnet" "webapp-subnet-1c" {
  vpc_id     = aws_vpc.webapp-vpc.id
  cidr_block = "10.10.2.0/24"
  availability_zone = "ap-south-1c"

  tags = {
    Name = "webapp-subnet-1c"
  }
}

#creating the EC2 server

resource "aws_instance" "webapp-instance-1" {
  ami           = "ami-0f58b397bc5c1f2e8"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.webapp-subnet-1a.id
  key_name = aws_key_pair.webapp-key.id
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.allow_22_80.id]
  user_data = filebase64("userdata.sh")

  tags = {
    Name = "Webapp-machine1"
  }
}


resource "aws_instance" "webapp-instance-2" {
  ami           = "ami-0f58b397bc5c1f2e8"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.webapp-subnet-1b.id
  key_name = aws_key_pair.webapp-key.id
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.allow_22_80.id]
  user_data = filebase64("userdata.sh")

  tags = {
    Name = "Webapp-machine2"
  }
}


resource "aws_key_pair" "webapp-key" {
  key_name   = "webapp-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCUoih1PxWGT/p2plBY6K6E+CrXa8vCA2C6udWyYbyQZGq0Di2cf2F3idSPFlQ7tr1UG/b1hhongrno2iRPw6eJCr5iYi3MO6cG2p/867aHuWO/SFzqY7tPDiJdjOueqDlBzOjEXySGaAhPLIeMLtFztw+kChdE0mqYv4zLKaIZHJgnvbwdHH3T7HkchEQHbAQ7ZgUOpKciVb5fer0NmmNk1FIjg2MK26W0p/uicgH2Wt8OfMTbQxufiVOAin9O/0gFWdSje+uI2wBhS3LxPv8q6n7PIfToqv1m3TP+lD8QQl/jWncQTgNRQPUqqgXmOmB5xiN45Sji6cD5x8cnNIMxHEhFhN4BJAKgL3R1C2G4TT5HOD0b4EWGRNM3yJ5mfK6GiIDvy5SiTcqrVn9WwwbF2h3/6JXHJB/E/yBmyh+lCJ8/LSG3G83beAyzLm4DmbxfQDzAN+wC/pKw18mwmNu4rpT83fjngxEVUe8eLgoAQgD5MMS7G5Qroga9C+lZULk= Amol@DESKTOP-2MVQBON"
}


#create Security Group

resource "aws_security_group" "allow_22_80" {
  name        = "allow_22_80"
  description = "Allow TLS inbound traffic 80 and 22"
  vpc_id      = aws_vpc.webapp-vpc.id

  tags = {
    Name = "allow_22_80"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_tls_22" {
  security_group_id = aws_security_group.allow_22_80.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "allow_tls_80" {
  security_group_id = aws_security_group.allow_22_80.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "allow_outbound" {
  security_group_id = aws_security_group.allow_22_80.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

resource "aws_vpc_security_group_egress_rule" "allow_outbound_traffic_ipv6" {
  security_group_id = aws_security_group.allow_22_80.id
  cidr_ipv6         = "::/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

#create IGW

resource "aws_internet_gateway" "webapp-IGW" {
  vpc_id = aws_vpc.webapp-vpc.id

  tags = {
    Name = "Webapp-internet-GW"
  }
}

#create RT

resource "aws_route_table" "webapp-public-RT" {
  vpc_id = aws_vpc.webapp-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.webapp-IGW.id
  }

  tags = {
    Name = "webapp-public-RT"
  }
}


resource "aws_route_table" "webapp-private-RT" {
  vpc_id = aws_vpc.webapp-vpc.id

  tags = {
    Name = "webapp-private-RT"
  }
}

resource "aws_route_table_association" "RT_asso_subnet_1_public" {
  subnet_id      = aws_subnet.webapp-subnet-1a.id
  route_table_id = aws_route_table.webapp-public-RT.id
}

resource "aws_route_table_association" "RT_asso_subnet_2_public" {
  subnet_id      = aws_subnet.webapp-subnet-1b.id
  route_table_id = aws_route_table.webapp-public-RT.id
}

resource "aws_route_table_association" "RT_asso_subnet_3_private" {
  subnet_id      = aws_subnet.webapp-subnet-1c.id
  route_table_id = aws_route_table.webapp-private-RT.id
}


#create SG for alb


resource "aws_security_group" "allow_80" {
  name        = "allow_80"
  description = "Allow TLS inbound traffic 80"
  vpc_id      = aws_vpc.webapp-vpc.id

  tags = {
    Name = "allow_80"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_tls_80_1" {
  security_group_id = aws_security_group.allow_80.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "allow_outbound_1" {
  security_group_id = aws_security_group.allow_80.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

resource "aws_vpc_security_group_egress_rule" "allow_outbound_traffic_ipv6_1" {
  security_group_id = aws_security_group.allow_80.id
  cidr_ipv6         = "::/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

#create Target group

resource "aws_lb_target_group" "webapp-target-group" {
  name     = "webapp-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.webapp-vpc.id
}

resource "aws_lb_target_group_attachment" "webapp-target-group-attach1" {
  target_group_arn = aws_lb_target_group.webapp-target-group.arn
  target_id        = aws_instance.webapp-instance-1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "webapp-target-group-attach2" {
  target_group_arn = aws_lb_target_group.webapp-target-group.arn
  target_id        = aws_instance.webapp-instance-2.id
  port             = 80
}

#aws alb 

resource "aws_lb" "webapp-alb" {
  name               = "webapp-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_80.id]
  subnets            = [aws_subnet.webapp-subnet-1a.id, aws_subnet.webapp-subnet-1b.id]


  tags = {
    Environment = "production"
  }
}

resource "aws_lb_listener" "webapp_listener" {
  load_balancer_arn = aws_lb.webapp-alb.arn
  port              = "80"
  protocol          = "HTTP"
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.webapp-target-group.arn
  }
}

#create the lauch template
resource "aws_launch_template" "webapp_launch_template" {
  name = "webapp_launch_template"
  image_id = "ami-0f58b397bc5c1f2e8"
  instance_type = "t2.micro"
  key_name = aws_key_pair.webapp-key.id
  vpc_security_group_ids = [aws_security_group.allow_22_80.id]
  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "webapp-machines-asg"
    }
  }

  user_data = filebase64("userdata.sh")
}


resource "aws_autoscaling_group" "webapp-asg" {
  #name_prefix = "webapp-asg-"
  vpc_zone_identifier = [aws_subnet.webapp-subnet-1a.id, aws_subnet.webapp-subnet-1b.id]
  desired_capacity   = 2
  max_size           = 5
  min_size           = 2
  target_group_arns = [aws_lb_target_group.webapp-target-group_2.arn]

  launch_template {
    id      = aws_launch_template.webapp_launch_template.id
    version = "$Latest"
  }
}

# ALB2


resource "aws_lb_target_group" "webapp-target-group_2" {
  name     = "webapp-target-group-2"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.webapp-vpc.id
}



resource "aws_lb" "webapp-alb-2" {
  name               = "webapp-alb-2"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_80.id]
  subnets            = [aws_subnet.webapp-subnet-1a.id, aws_subnet.webapp-subnet-1b.id]


  tags = {
    Environment = "production"
  }
}

resource "aws_lb_listener" "webapp_listener_2" {
  load_balancer_arn = aws_lb.webapp-alb-2.arn
  port              = "80"
  protocol          = "HTTP"
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.webapp-target-group_2.arn
  }
}

# resource "aws_autoscaling_policy" "webapp-policy" {
#     name = "webapp_policu"
#     autoscaling_group_name = aws_autoscaling_group.webapp-asg.name

#     policy_type            = "TargetTrackingScaling"
#     target_tracking_configuration {
#     target_value = 60
#     customized_metric_specification {
#       metrics {
#         label = "Get the queue size (the number of messages waiting to be processed)"
#         id    = "m1"
#         metric_stat {
#           metric {
#             namespace   = "AWS/SQS"
#             metric_name = "ApproximateNumberOfMessagesVisible"
#             dimensions {
#               name  = "QueueName"
#               value = "my-queue"
#             }
#           }
#           stat = "Sum"
#         }
#         return_data = false
#       }
#       metrics {
#         label = "Get the group size (the number of InService instances)"
#         id    = "m2"
#         metric_stat {
#           metric {
#             namespace   = "AWS/AutoScaling"
#             metric_name = "GroupInServiceInstances"
#             dimensions {
#               name  = "AutoScalingGroupName"
#               value = "my-asg"
#             }
#           }
#           stat = "Average"
#         }
#         return_data = false
#       }
#       metrics {
#         label       = "Calculate the backlog per instance"
#         id          = "e1"
#         expression  = "m1 / m2"
#         return_data = true
#       }
#     }
#     }

# }