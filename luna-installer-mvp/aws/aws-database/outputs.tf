/*************************************************************************
 Database Outputs 
*************************************************************************/
output "db-instance-address" {
  description = "The address of the RDS instance"
  value       = "${module.db.this_db_instance_address}"
}

output "db-instance-arn" {
  description = "The ARN of the RDS instance"
  value       = "${module.db.this_db_instance_arn}"
}

output "db-instance-availability-zone" {
  description = "The availability zone of the RDS instance"
  value       = "${module.db.this_db_instance_availability_zone}"
}

output "db-instance-endpoint" {
  description = "The connection endpoint"
  value       = "${module.db.this_db_instance_endpoint}"
}

output "db-instance-hosted-zone-id" {
  description = "The canonical hosted zone ID of the DB instance (to be used in a Route 53 Alias record)"
  value       = "${module.db.this_db_instance_hosted_zone_id}"
}

output "db-instance-id" {
  description = "The RDS instance ID"
  value       = "${module.db.this_db_instance_id}"
}

output "db-instance-resource-id" {
  description = "The RDS Resource ID of this instance"
  value       = "${module.db.this_db_instance_resource_id}"
}

output "db-instance-status" {
  description = "The RDS instance status"
  value       = "${module.db.this_db_instance_status}"
}

output "db-instance-name" {
  description = "The database name"
  value       = "${module.db.this_db_instance_name}"
}

output "db-instance-username" {
  description = "The master username for the database"
  value       = "${module.db.this_db_instance_username}"
}

output "db-instance-password" {
  description = "The database password (this password may be old, because Terraform doesn't track it after initial creation)"
  value       = "${module.db.this_db_instance_password}"
}

output "db-instance-port" {
  description = "The database port"
  value       = "${module.db.this_db_instance_port}"
}

output "db-subnet-group-id" {
  description = "The db subnet group name"
  value       = "${module.db.this_db_subnet_group_id}"
}

output "db-subnet-group-arn" {
  description = "The ARN of the db subnet group"
  value       = "${module.db.this_db_subnet_group_arn}"
}

output "db-parameter-group-id" {
  description = "The db parameter group id"
  value       = "${module.db.this_db_parameter_group_id}"
}

output "db-parameter-group-arn" {
  description = "The ARN of the db parameter group"
  value       = "${module.db.this_db_parameter_group_arn}"
}

output "region" {
  description = "The region of the db"
  value       = "${var.region}"
}
