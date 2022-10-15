# statelocking.tf
# create a dynamodb table for locking the state file
resource "aws_dynamodb_table" "aws-poc-state-lock-dynamo" {
  name = "aws-poc-state-lock-dynamo"
  hash_key = "LockID"
  billing_mode = "PROVISIONED" 
  read_capacity = 20
  write_capacity = 20
 
  attribute {
    name = "LockID"
    type = "S"
  }
 
  tags =  {
    Name = "DynamoDB Terraform State Lock Table"
    Date = timestamp()
  }
}