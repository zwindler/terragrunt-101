module "cloud-storage-states-bucket" {
    source = "terraform-google-modules/cloud-storage/google"
    version = "3.1.0"
    project_id = var.project_name
    location = var.location
    prefix = var.project_name
    names = [
        "product1",
        "product2",
        "shared-services",
    ]
    versioning = {
        "product1" = true
        "product2" = true
        "shared-services" = true
    }
    set_admin_roles = true
    set_viewer_roles = false
    set_storage_admin_roles = true
    randomize_suffix = false
}