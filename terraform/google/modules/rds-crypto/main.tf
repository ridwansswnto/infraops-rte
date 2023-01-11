resource "google_kms_key_ring" "cluster-keyring" {
  project  = var.service_project
  name     = "${var.cluster_name}-secrets"
  location = var.cluster_location # xxx: doesn't support zonal clusters
}

resource "google_kms_crypto_key" "cluster-key" {
  name            = "${var.cluster_name}-secret"
  key_ring        = google_kms_key_ring.cluster-keyring.self_link
  rotation_period = "2592000s"
  purpose         = "ENCRYPT_DECRYPT"
  lifecycle {
    prevent_destroy = false
  }
}

data "google_project" "service_project" {
  project_id = var.service_project
}

resource "google_kms_crypto_key_iam_binding" "crypto_key" {
  crypto_key_id = google_kms_crypto_key.cluster-key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"

  members = [
    "serviceAccount:service-${data.google_project.service_project.number}@container-engine-robot.iam.gserviceaccount.com"
  ]
}
