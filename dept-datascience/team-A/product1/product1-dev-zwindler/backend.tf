terraform {
    backend "gcs" {
        bucket  = "states-bucket-eu-product1"
        prefix  = "product1-dev-zwindler"
    }
}