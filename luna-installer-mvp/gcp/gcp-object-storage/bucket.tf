# Create a GCS Bucket
resource "google_storage_bucket" "tf-bucket" {
  project = var.gcp_project_id
  name    = "${local.bucket-name}-tfstate"
  labels        = var.cluster-tags
  force_destroy = true
  versioning {
    enabled = true
  }

}
