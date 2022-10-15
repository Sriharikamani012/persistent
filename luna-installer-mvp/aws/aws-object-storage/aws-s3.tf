/*************************************************************************
S3 Bucket Deployment 
*************************************************************************/
data "aws_caller_identity" "current" {}

module "s3_bucket" {
  source                               = "terraform-aws-modules/s3-bucket/aws"
  version                              = "1.15.0"

  bucket                               = local.bucket-name 
  acl                                  = "private"
  block_public_acls	                   = true
  restrict_public_buckets              = true

  #TODO Case statement to use aws default encryption if the kms key is not provided
  server_side_encryption_configuration = { #TODO Parameterize this
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id              = var.kms-master-key-id
        sse_algorithm                  = "aws:kms"
      }
    }
  }

  #TODO Get information on what sort of access policy is necessary 

  # versioning = {
  #   enabled  = true
  # }

  force_destroy                        = true
  tags                                 = var.cluster-tags
}
