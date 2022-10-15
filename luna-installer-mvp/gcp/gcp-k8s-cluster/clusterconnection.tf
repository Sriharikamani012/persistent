/*************************************************************************
 GCP Networking - Creates the Cloud Router and Cloud NAT for Egress Traffic
*************************************************************************/

resource "random_integer" "priority" {
  min     = 64512
  max     = 65534
}

data "google_compute_network" "connect-vpc" {
  name    = var.vpc-name
  project = var.gcp_project_id
}

data "google_compute_subnetwork" "connect-subnet" {
  name    = var.vpc-subnet-name
  project = var.gcp_project_id
  region  = var.region
}

resource "google_compute_router" "cloud-router" {
  name    = "${local.customer-name}-gke-router"
  project = var.gcp_project_id
  region  = var.region
  network = data.google_compute_network.connect-vpc.name
  bgp {
    asn               = random_integer.priority.result
    advertise_mode    = "CUSTOM"
  }
}

resource "google_compute_router_nat" "cloud-nat" {
  name                               = "${local.customer-name}-gke-nat"
  project                            = var.gcp_project_id
  router                             = google_compute_router.cloud-router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  subnetwork {
    name = data.google_compute_subnetwork.connect-subnet.self_link
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  } 
}

