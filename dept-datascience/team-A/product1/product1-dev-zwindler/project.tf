module "project" {
  source          = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/project"
  billing_account = "01AB34-CD56EF-78GH90"
  name            = "product1-dev-zwindler"
  parent          = "folders/123456789012"
  services        = []
}