##############################################################
# Data sources to get VPC, subnets and security group details
##############################################################

data "aws_subnet_ids" "all" {
  vpc_id           = var.vpc-id
  filter {
    name   = "tag:type"
    values = ["private"]
  }
}

data "aws_security_group" "eks-k8s-cluster" {
  vpc_id           = var.vpc-id

  tags = {
    "Name" = format("%s-k8s-00%d-eks-eks_cluster_sg", local.customer-name, var.infra-version-suffix)
  }
}

data "aws_security_group" "eks-k8s-worker" {
  vpc_id           = var.vpc-id

  tags = {
    "Name" = format("%s-k8s-00%d-eks-eks_worker_sg", local.customer-name, var.infra-version-suffix)
  }
}

# NOTE - Using port 5432 can be a security risk, and is not typically recommended for production workloads.
resource "aws_security_group_rule" "database-port" {
  description              = "Allow database to communicate with the EKS cluster2."
  protocol                 = "tcp"
  security_group_id        = data.aws_security_group.eks-k8s-cluster.id

  source_security_group_id = data.aws_security_group.eks-k8s-worker.id
  from_port                = 5432
  to_port                  = 5432
  type                     = "ingress"
}

resource "random_password" "password" {
  length           = 25
  special          = false
  override_special = "!#$%^&*()-_=+[]{}<>:?"
}

##############################################################
# Database 
##############################################################
module "db" {
  source                  = "terraform-aws-modules/rds/aws"
  version                 = "2.20.0"

  identifier              = local.database-name

  engine                  = "postgres"
  engine_version          = "11.5" 
  instance_class          = "db.t3.small"  
  allocated_storage       = 5
  storage_encrypted       = true

  kms_key_id              = var.kms-master-key-id
  name                    = local.database-name 

  username                = "postgres" 

  password                = random_password.password.result
  port                    = "5432"

  vpc_security_group_ids  = [data.aws_security_group.eks-k8s-cluster.id] 

  maintenance_window      = "Mon:00:00-Mon:03:00"
  backup_window           = "03:00-06:00"

  # Disable backups to create DB faster
  backup_retention_period         = 3

  tags                            = var.luna-tags
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  # DB subnet group
  subnet_ids                      = data.aws_subnet_ids.all.ids

  # DB parameter group
  family                          = "postgres11"

  # DB option group
  major_engine_version            = "11" 

  # Snapshot name upon DB deletion
  final_snapshot_identifier       = "demodb"

  # Database Deletion Protection
  deletion_protection             = false 
}
