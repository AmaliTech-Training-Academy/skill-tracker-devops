data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_security_group" "monitoring" {
  name        = "${var.project_name}-${var.environment}-observability-sg"
  description = "Security group for Prometheus/Grafana EC2"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.ssh_allowed_cidrs
    content {
      description = "SSH"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  dynamic "ingress" {
    for_each = var.web_allowed_cidrs
    content {
      description = "Grafana"
      from_port   = 3000
      to_port     = 3000
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  dynamic "ingress" {
    for_each = var.web_allowed_cidrs
    content {
      description = "Prometheus"
      from_port   = 9090
      to_port     = 9090
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-observability-sg"
  })
}

resource "aws_instance" "monitoring" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.instance_type
  subnet_id                   = var.public_subnet_ids[0]
  vpc_security_group_ids      = [aws_security_group.monitoring.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.monitoring.name

  user_data = templatefile("${path.module}/user-data.sh", {
    region                      = var.aws_region
    service_discovery_namespace = var.service_discovery_namespace
    adot_exporter_port          = var.adot_exporter_port
    grafana_admin_password      = var.grafana_admin_password
  })
  user_data_replace_on_change = true

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-observability"
  })
}
