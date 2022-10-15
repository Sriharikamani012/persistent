/*************************************************************************
 AWS - EKS Cluster Module Implementation
 Helpful Documentation - https://blog.gruntwork.io/comprehensive-guide-to-eks-worker-nodes-94e241092cbe
                       - https://aws.amazon.com/blogs/containers/de-mystifying-cluster-networking-for-amazon-eks-worker-nodes/ 
*************************************************************************/

resource "aws_iam_role" "test_role" {
  name = "${local.customer-name}-${random_string.this.id}-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = var.cluster-tags
}

resource "aws_iam_role_policy_attachment" "role-policy-attachment" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSServicePolicy",
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController", 
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"

  ])

  role       = aws_iam_role.test_role.name
  policy_arn = each.value
  
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

resource "aws_iam_instance_profile" "kubectl-access-profile" {
  name = "${local.customer-name}-${random_string.this.id}-access-profile" 
  role = aws_iam_role.test_role.name  
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "12.2.0"

  cluster_name    = "${local.cluster-name}"
  cluster_version = var.k8s-version
  subnets         = module.vpc.private_subnets
  vpc_id          = module.vpc.vpc_id 
  enable_irsa     = true

  cluster_create_timeout = "20m"
  cluster_delete_timeout = "20m"  

  tags            = merge(
    { 
    Environment   = "test"
    GithubRepo    = "terraform-aws-eks"
    GithubOrg     = "terraform-aws-modules"
  },
   var.cluster-tags
  )
  


  #Logging 
  cluster_enabled_log_types     = ["api", "audit", "authenticator", "controllerManager", "scheduler"] 
  cluster_log_retention_in_days = 90


  #Security 
  cluster_security_group_id     = var.cluster-security-group-id
  cluster_create_security_group = true #var.cluster-create-security-group


  # Private Cluster Variables
  cluster_endpoint_private_access        = true
  cluster_endpoint_public_access         = false

  #TODO either create a new kms key with a terraform object 
  #OR
  #Accept a KMS Key from the input form 
  cluster_encryption_config = [
    {
      provider_key_arn = var.kms-master-key-id
      resources        = ["secrets"]
    }
  ]
 
  worker_groups = [
    {
      name                          = "worker-group-linux"
      instance_type                 = "m5.xlarge"
      platform                      = "linux"
      asg_desired_capacity          = 3
      asg_max_size                  = 10
      asg_min_size                  = 3
      tags = [
      {
          "key"                 = "k8s.io/cluster-autoscaler/enabled"
          "propagate_at_launch" = "false"
          "value"               = "true"
        },
        {
          "key"                 = "k8s.io/cluster-autoscaler/${local.cluster-name}"
          "propagate_at_launch" = "false"
          "value"               = "true"
        }
      ]
    },
  ]

  map_roles    = [{
                  rolearn  = aws_iam_role.test_role.arn
                  username = aws_iam_role.test_role.name
                  groups   = ["system:masters"]
                 }]  #TODO change this to an array here
  map_users    = [{
                  userarn  = var.service-account-id
                  username = var.service-account-name
                  groups   = ["system:masters"]
                 }]
  map_accounts = [var.aws-account-num ]
}

resource "aws_iam_role_policy_attachment" "CloudWatchPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = module.eks.worker_iam_role_name
}