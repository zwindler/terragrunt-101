module "folder-dept-datascience" {
  source = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/folder"
  parent = "organizations/246461292578"
  name  = "dept-datascience"
  iam = {
    "roles/owner" = ["user:blog@zwindler.fr"]
  }
}

module "folder-team-A" {
  source = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/folder"
  parent = module.folder-dept-datascience.id
  name  = "team-A"
  iam = {
    "roles/owner" = ["user:blog@zwindler.fr"]
  }
}

module "folder-team-A-product1" {
  source = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/folder"
  parent = module.folder-team-A.id
  name  = "product1"
  iam = {
    "roles/owner" = ["user:blog@zwindler.fr"]
  }
}

module "folder-team-A-product2" {
  source = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/folder"
  parent = module.folder-team-A.id
  name  = "product2"
  iam = {
    "roles/owner" = ["user:blog@zwindler.fr"]
  }
}