# EC2 Instance for Prometheus + Grafana
resource "aws_instance" "monitoring" {
  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = var.instance_type
  
  subnet_id                   = var.public_subnet_id
  vpc_security_group_ids      = [aws_security_group.monitoring.id]
  associate_public_ip_address = true
  
  iam_instance_profile = aws_iam_instance_profile.monitoring.name
  
  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    prometheus_version = var.prometheus_version
    grafana_version    = var.grafana_version
    aws_region         = var.aws_region
    ecs_cluster_name   = var.ecs_cluster_name
    environment        = var.environment
    project_name       = var.project_name
  }))
  
  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = true
  }
  
  # Additional volume for Prometheus data
  ebs_block_device {
    device_name           = "/dev/sdf"
    volume_size           = var.prometheus_volume_size
    volume_type           = "gp3"
    delete_on_termination = false
    encrypted             = true
  }
  
  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-monitoring"
      Role = "Observability"
    }
  )
}

# Data source for latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
  
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Security Group for Monitoring Instance
resource "aws_security_group" "monitoring" {
  name        = "${var.project_name}-${var.environment}-monitoring-sg"
  description = "Security group for Prometheus and Grafana"
  vpc_id      = var.vpc_id
  
  # Grafana Web UI
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
    description = "Grafana Web UI"
  }
  
  # Prometheus Web UI
  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
    description = "Prometheus Web UI"
  }
  
  # Prometheus Remote Write (from ADOT)
  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "Prometheus Remote Write from ECS"
  }
  
  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
    description = "SSH access"
  }
  
  # Allow all outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }
  
  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-monitoring-sg"
    }
  )
}

# IAM Role for EC2 Instance
resource "aws_iam_role" "monitoring" {
  name = "${var.project_name}-${var.environment}-monitoring-role"
  
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
  
  tags = var.tags
}

# IAM Policy for CloudWatch and ECS access
resource "aws_iam_role_policy" "monitoring" {
  name = "${var.project_name}-${var.environment}-monitoring-policy"
  role = aws_iam_role.monitoring.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics",
          "cloudwatch:GetMetricData",
          "ecs:ListClusters",
          "ecs:ListServices",
          "ecs:DescribeServices",
          "ecs:ListTasks",
          "ecs:DescribeTasks",
          "ecs:DescribeTaskDefinition",
          "ec2:DescribeInstances",
          "ec2:DescribeVolumes",
          "logs:GetLogEvents",
          "logs:FilterLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      }
    ]
  })
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "monitoring" {
  name = "${var.project_name}-${var.environment}-monitoring-profile"
  role = aws_iam_role.monitoring.name
  
  tags = var.tags
}

# Elastic IP for stable access
resource "aws_eip" "monitoring" {
  count    = var.create_elastic_ip ? 1 : 0
  instance = aws_instance.monitoring.id
  domain   = "vpc"
  
  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-monitoring-eip"
    }
  )
}
