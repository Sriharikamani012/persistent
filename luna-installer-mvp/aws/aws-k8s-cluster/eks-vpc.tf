/*************************************************************************
 AWS VPC Module Implementation
*************************************************************************/
data "aws_availability_zones" "available" {
}

module "vpc" {
  # TODO Add Case Statement for situations when the customer provides these subnets 
  source  = "../aws-modules/terraform-aws-vpc"

  name                 = format("%s-vpc-00%d", local.customer-name, var.infra-version-suffix)
  cidr                 = var.vpc-cidr
  vpc_id               = var.vpc-id
  ui_managed_subnets   = [ var.publicSubnet1]
  azs                  = data.aws_availability_zones.available.names
  private_subnets      = [var.privateSubnet1, var.privateSubnet2, var.privateSubnet3]
  public_subnets       = [ var.publicSubnet2, var.publicSubnet3] #publicSubnet1 is created by the UI
  
  enable_nat_gateway   = true 
  single_nat_gateway   = true 
  enable_dns_hostnames = true 
  create_igw           = true

  enable_flow_log                      = true
  create_flow_log_cloudwatch_iam_role  = true
  create_flow_log_cloudwatch_log_group = true
  
  
  enable_s3_endpoint   = false

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster-name}" = "shared"
    "kubernetes.io/role/elb"                      = "1"
    "type"                                        = "public"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster-name}" = "shared"
    "kubernetes.io/role/internal-elb"             = "1"
    "type"                                        = "private"
  }

  tags                = var.cluster-tags

}

#TODO Add Cloud Watch Logs








