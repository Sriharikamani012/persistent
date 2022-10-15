/*************************************************************************
 GCP Database Implementation
*************************************************************************/
data "google_compute_network" "vpc" {
  name    = var.vpc-name
  project = var.gcp_project_id
}

resource "random_password" "password" {
  length           = 25
  special          = true
  override_special = "!#$%^&*()-_=+[]{}<>:?"
}

resource "google_compute_global_address" "private_ip_address" {
  project       = var.gcp_project_id
  name          = "${var.vpc-name}-ip"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = data.google_compute_network.vpc.id
}

resource "google_service_networking_connection" "private_vpc_connection" {

  network                 = data.google_compute_network.vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}

resource "random_id" "db_name_suffix" {
  byte_length = 4
}

resource "google_sql_database_instance" "instance" {
  project             = var.gcp_project_id
  name                = "private-instance-${random_id.db_name_suffix.hex}"
  region              = var.region
  database_version    = "POSTGRES_11"
  deletion_protection = false
  depends_on          = [google_service_networking_connection.private_vpc_connection]

  settings {
    user_labels = var.cluster-tags
    tier        = "db-f1-micro"
    ip_configuration {
      ipv4_enabled    = false
      private_network = data.google_compute_network.vpc.id
    }
    backup_configuration {
      enabled    = "true"
      start_time = "03:00"
    }
  }
}

resource "google_sql_user" "users" {
  name     = "postgres"
  instance = google_sql_database_instance.instance.name
  project  = var.gcp_project_id
  password = random_password.password.result
}
