terraform {
    backend "gcs" {
        bucket  = "states-bucket-eu-shared-services"
        prefix  = "states-bucket"
    }
}