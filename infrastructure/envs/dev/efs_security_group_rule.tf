# Additional security group rule for EFS to allow data services access
# This is defined at root level to avoid circular dependency between EFS and data_services modules
resource "aws_security_group_rule" "efs_from_data_services" {
  type                     = "ingress"
  from_port                = 2049
  to_port                  = 2049
  protocol                 = "tcp"
  source_security_group_id = module.data_services.data_services_security_group_id
  security_group_id        = module.efs.efs_security_group_id
  description              = "NFS from data services (MongoDB, Redis, RabbitMQ)"
}
