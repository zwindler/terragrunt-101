module "project" {
  source          = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/project"
  billing_account = var.billing_account
  name            = var.project_name
  parent          = var.folder_id
  labels          = local.labels
  services        = []
}