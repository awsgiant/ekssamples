# ekssamples

provider "aws" {
  region = "us-west-2" # replace with your desired region
}

resource "aws_eks_nodegroup" "example" {
  cluster_name    = aws_eks_cluster.example.name
  node_group_name = "example-descheduler"

  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }

  instance_types = ["t3.small"]

  launch_template {
    name = "example-descheduler"

    image_id = "ami-0c55b159cbfafe1f0" # replace with your desired AMI

    instance_type = "t3.small"

    iam_instance_profile {
      name = aws_iam_instance_profile.example.name
    }

    security_group_ids = [aws_security_group.example.id]

    tag_specifications {
      resource_type = "instance"
      tags = {
        Name = "example-descheduler"
      }
    }
  }

  depends_on = [aws_eks_cluster.example]
}

resource "aws_iam_role" "example" {
  name = "example-descheduler"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_instance_profile" "example" {
  name = "example-descheduler"

  role = aws_iam_role.example.name
}

resource "aws_security_group" "example" {
  name_prefix = "example-descheduler"

  ingress {
    from_port = 0
    to_port   = 65535
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port   = 65535
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "example-descheduler"
  }
}

resource "aws_eks_cluster" "example" {
  name     = "example-cluster"
  role_arn = aws_iam_role.example.arn

  vpc_config {
    subnet_ids = ["subnet-12345678", "subnet-23456789", "subnet-34567890"] # replace with your subnet IDs
  }

  depends_on = [aws_iam_role.example]
}
