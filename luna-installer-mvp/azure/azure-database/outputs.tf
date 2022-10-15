/*************************************************************************
 Database Outputs 
*************************************************************************/
output "db-instance-username" {
  description = "The master username for the database"
  value       = "lunaclusteradmin"  
}

output "db-instance-password" {
  description = "The database password (this password may be old, because Terraform doesn't track it after initial creation)"
  value       = random_password.password.result
}

#TODO Export endpoints
