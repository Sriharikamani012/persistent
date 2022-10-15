/*************************************************************************
 Output File 
*************************************************************************/
output "bucket_name" {
  description = "name of created bucket"
  value       = google_storage_bucket.tf-bucket.name
}
