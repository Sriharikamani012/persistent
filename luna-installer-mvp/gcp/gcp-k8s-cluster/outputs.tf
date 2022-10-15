/*************************************************************************
 Output File 
*************************************************************************/

output "cluster_name" {
  description = "name of cluster created"
  value       = google_container_cluster.primary.name
}

output "cluster_zone" {
  description = "zone where cluster is placed"
  value       = google_container_cluster.primary.location
}

output "vpc_id" {
  description = "vpc id"
  value       = data.google_compute_network.vpc.id
}

output "vpc_subnet_id" {
  description = "vpc subnet id"
  value       = data.google_compute_subnetwork.subnet.id
}