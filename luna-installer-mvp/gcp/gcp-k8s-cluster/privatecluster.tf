/*************************************************************************
 GCP Cluster Implementation
*************************************************************************/
#Create kubernetes cluster
data "google_container_engine_versions" "us-central1-version" {
  location       = var.region
  project        = var.gcp_project_id
  version_prefix = var.k8s-version
}

data "google_compute_network" "vpc" {
  name    = var.vpc-name
  project = var.gcp_project_id
}

data "google_compute_subnetwork" "subnet" {
  name    = var.vpc-subnet-name
  project = var.gcp_project_id
  region = var.region
}

resource "google_container_cluster" "primary" {
  name     = "${local.cluster-name}-gcp"
  location = var.zone
  project  = var.gcp_project_id
  node_version = data.google_container_engine_versions.us-central1-version.version_prefix
  min_master_version = var.k8s-version
  
  release_channel {
    channel = "UNSPECIFIED"
  }
  resource_labels = var.cluster-tags
  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1
  network                  = data.google_compute_network.vpc.name
  subnetwork               = data.google_compute_subnetwork.subnet.name

  master_auth {
    username = ""
    password = ""

    client_certificate_config {
      issue_client_certificate = false
    }
  }

  ip_allocation_policy {
    cluster_ipv4_cidr_block  = "/14"
    services_ipv4_cidr_block = "/20"
  }
  #Makes cluster private
  private_cluster_config {
    enable_private_nodes    = "true"
    enable_private_endpoint = "true"
    master_ipv4_cidr_block  = var.master-private-cluster-ipv4
  }

  # By not having any cidr's specified here there is no public end point
  master_authorized_networks_config {
  }
  
  logging_service    = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"

  timeouts {
    create = "60m"
 }
}
#Creates nodes in the cluster
resource "google_container_node_pool" "linux_pool" {
  name       = "${local.cluster-name}-linux-pool"
  location   = var.zone
  cluster    = google_container_cluster.primary.name
  project    = var.gcp_project_id
  node_count = "3"
  node_locations = [
    var.zone
  ]
  autoscaling {
    min_node_count = "3"
    max_node_count = "4"
  }

  node_config {
    machine_type = "e2-standard-4"
    image_type   = "COS_CONTAINERD"

    metadata = {
      disable-legacy-endpoints = "true"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}

resource "google_container_node_pool" "windows_pool" {
  name       = "${local.cluster-name}-windows-pool"
  location   = var.zone
  cluster    =  "${local.cluster-name}-gcp"
  project    = var.gcp_project_id
  version    = var.k8s-version
  node_count = 3
  node_locations = [
    var.zone
  ]
  node_config {
    machine_type = "n1-standard-2"
    image_type   = "WINDOWS_LTSC"

    metadata = {
      disable-legacy-endpoints = "true"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
  depends_on = [google_container_node_pool.linux_pool]
  timeouts {
    create = "60m"
    delete = "60m"
    update = "60m"
  }
}
