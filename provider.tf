terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.61.0"
    }
  }
  backend "gcs" {
    bucket = "parisaiacweu"
    prefix = "gcp-solution-gke/weu4"
  }
}


# install gcloud cli : https://cloud.google.com/sdk/docs/install