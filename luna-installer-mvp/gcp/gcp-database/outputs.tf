/*************************************************************************
 Database Output File 
*************************************************************************/

output "user_password" {
  description = "password generated for user we created"
  value       = google_sql_user.users.password
}

output "database_instance_name" {
  description = "name of the database instance"
  value       = google_sql_database_instance.instance.name
}

#TODO export the endpoints 