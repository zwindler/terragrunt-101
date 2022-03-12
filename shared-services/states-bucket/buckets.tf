module "cloud-storage-states-bucket" {
    source = "terraform-google-modules/cloud-storage/google"
    version = "3.1.0"
    project_id = var.project_name
    location = var.location
    prefix = var.project_name
    names = [
        "product1-dev-zwindler",
        "product1-prod-zwindler",
        "product2-dev-zwindler",
        "product2-prod-zwindler",
        "shared-services-zwindler",
    ]
    versioning = {
        "product1-dev-zwindler" = true
        "product1-prod-zwindler" = true
        "product2-dev-zwindler" = true
        "product2-prod-zwindler" = true
        "shared-services-zwindler" = true
    }
    set_admin_roles = true
    set_viewer_roles = false
    set_storage_admin_roles = true
    randomize_suffix = false
}