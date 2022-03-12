# Terragrunt 101

## Prerequisites

Create a free Google Cloud account (with 300$ credits)

Login in console to find billing account

```
#ex.
01AB34-CD56EF-78GH90
```

Activate "Cloud Indetity" to unlock organisations and folders. 

In IAM, add your account as 
* organisation admin 
* folder creator
* project creator

Get your org ID

```
#ex.
123456789012
```

Install gcloud CLI

```bash
sudo apt-get install apt-transport-https ca-certificates gnupg
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
sudo apt-get update && sudo apt-get install google-cloud-cli
```

Login you shell session in Google cloud

```bash
gcloud auth login

[browser opens]

You are now logged in as [xxx@yyy.tld].
```

Install terraform and terragrunt (latest versions are respectively 1.1.7 and v0.36.3 at time of writing)

```bash
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install terraform

wget https://github.com/gruntwork-io/terragrunt/releases/download/v0.36.3/terragrunt_linux_amd64
chmod +x terragrunt_linux_amd64
sudo mv terragrunt_linux_amd64 /usr/local/bin/terragrunt
```

## Folders & projects hierarchy

```
└── terragrunt
    ├── dept-datascience
    │   └── team-A
    │       ├── product1
    │       │   ├── product1-dev-zwindler
    │       │   └── product1-prod-zwindler
    │       └── product2
    │           ├── product2-dev-zwindler
    │           └── product2-prod-zwindler
    └── shared-services
```

Create all the folders

```bash
cd shared-services/folders
terraform init
terraform apply
```

## Create terraform state buckets

Now we kinda have a chicken and egg issue with the bucket creation because state can't be stored for the project as the bucket is not yet created. Either create the bucket manually or remove the backend.tf file temporarily

```bash
cd shared-services/states-bucket
terraform init
terraform apply
```

## Deploy a project

Once the folders are created, get the folders ID, and configure the project variables (ex. ` dept-datascience/team-A/product1/product1-dev-zwindler/variables.tf`) to include the good folderID and billing account from previous steps

Deploy one project

```bash
cd dept-datascience/team-A/product1/product1-dev-zwindler
terraform init
terraform apply
```

Now we have a working IaC environment with Terraform and Google Cloud. 

[Step 1 - 082127c](https://github.com/zwindler/terragrunt/tree/082127c3bd4bc75725bf1b96ebaeec0aa1fa959a)

## Switching to terragrunt

The idea here is now to *improve* our IaC codebase by factoring variables (with terragrunt) in a way we couln't with terraform. It's especially annoying when you have carefully planned your IaC directories hierarchy because a lot of variables / informations can be deduced from path names.

In our example, we can deduce the department, the team, the product, and the environment of a given project just by looking at its path... And for each level in the directory tree, many variables can be shared.

If all goes well, changing the way our code works with terragrunt should have **NO** impact on "plan" which shouldn't see any change.

First, we need to create at bottom level a terragrunt.hcl file in `dept-datascience/team-A/product1/product1-dev-zwindler`. In this file, we are going to tell terragrunt to look upward in the directory hierarchy for a "global.hcl" file which will contain all the variables we ALWAYS NEED and never change like the billing_account for example.

```hcl
cat > dept-datascience/team-A/product1/product1-dev-zwindler/terragrunt.hcl << EOF
inputs = merge(
    read_terragrunt_config(find_in_parent_folders("global.hcl")).inputs,
)
EOF
```

Note: We could have specified an absolute path in `read_terragrunt_config` function (sometimes it's useful) but having the option to tell terragrunt to manage this by himself is a big help.

Then, we create the global.hcl file at top level so that all subdirectories can benefit from it.

```hcl
cat > global.hcl << EOF
inputs = {
    billing_account = "01AB34-CD56EF-78GH90"
}
EOF
```

Finally, we replace the value of billing_account in `dept-datascience/team-A/product1/product1-dev-zwindler/variables.tf` by it's type/

Note: that's something I haven't found how to workaround yet.

```tf
variable "billing_account" {
    type = string
    # was previously 'default = "01AB34-CD56EF-78GH90"'
}
```

If all goes well, making a `terragrunt plan` should not see any difference (which is what we expect).

```bash
terragrunt plan
module.project.google_project.project[0]: Refreshing state... [id=projects/product1-dev-zwindler]

No changes. Your infrastructure matches the configuration.

Terraform has compared your real infrastructure against your configuration
and found no differences, so no changes are needed.
```

Note: another *nice to have* terragrunt feature in comparison to terraform is that you don't have to run "terraform init" anymore. terragrunt ships an "auto init" features which is especially usefull when you heavily use external modules. They which need `terraform init` to be rerun everytime you add a module, *even you used the same module before*.

## Factoring a few variables we can guess

We already told that we could "deduce" some of the variables from the directory architecture. We are going to leverage this to factor the project name, which is equal to the folder name in the terraform directory in this example.

Like in the previous section, we are going the replace the **project_name** variable default by it's type in `dept-datascience/team-A/product1/product1-dev-zwindler/variables.tf`

```tf
variable "project_name" {
    type = string
}
```

And in the terragrunt.hcl file, in the inputs section, we are going to add a line for the project_name variable:

```hcl
inputs = merge(
    read_terragrunt_config(find_in_parent_folders("global.hcl")).inputs,
    #add these 3 lines
    {
        project_name = "${basename(get_terragrunt_dir())}"
    }
)
```

Again, terragrunt should not see any difference

```bash
terragrunt plan
module.project.google_project.project[0]: Refreshing state... [id=projects/product1-dev-zwindler]

No changes. Your infrastructure matches the configuration.

Terraform has compared your real infrastructure against your configuration
and found no differences, so no changes are needed.
```

## Factor terragrunt.hcl itself

Factoring variables using intermediate files that can be applied to multiple directories is fun, but we can do better.

We are going to use the same tactic (looking upward) to replace completely terragrunt.hcl file with one that contains only 3 generic lines. We are going to create a top level `terragrunt.hcl` , where the real "factoring magic" will happen for all projects of our repo!!

```hcl
mv dept-datascience/team-A/product1/product1-dev-zwindler/terragrunt.hcl terragrunt.hcl 
cat > dept-datascience/team-A/product1/product1-dev-zwindler/terragrunt.hcl << EOF
include "root" {
    path = find_in_parent_folders("terragrunt.hcl")
}
EOF
```

Here you can see that I just "moved" the terragrunt.hcl we previously built to the top level, but now we can access it from any subdirectory with only 3 lines of hcl, which is going to save us a lot of lines of code if we have lots of projects.

You can check that this works by *again* run a `terragrunt plan` which should *again* not see any difference.

## Factoring remote state backend

One really annoying pain point with terraform is that **you cannot** use variables in you backend configuration. Hopefully terragrunt fixes this.

If we look at product1-dev-zwindler backend configuration, we can deduce that:
* bucket name is shared (in this example) for all **product1** projects (dev and prod here)
* state prefix (the path of the state file in the bucket) is equal to the project name, which is itself the name of the terraform folder and can be deduced

```tf
bucket  = "states-bucket-eu-product1"
prefix  = "product1-dev-zwindler"
```

We are going to replace our `dept-datascience/team-A/product1/product1-dev-zwindler/backend.tf` remote state configuration file by an empty one. This will tell terragrunt to look upward for backend configuration.

```hcl
cat > dept-datascience/team-A/product1/product1-dev-zwindler/backend.tf << EOF
terraform{
    backend "gcs" {}
}
EOF
```

Then, we are going to add a backend.hcl file in `dept-datascience/team-A/product1` which is going be used by all the product1 projects.

```bash
cat > dept-datascience/team-A/product1/backend.hcl << EOF
inputs = {
    bucket = "states-bucket-eu-product1"
}
EOF
```

Finally, we add the following section in our top-level terragrunt.hcl:

```hcl
remote_state {
    backend = "gcs"
    config = {
        bucket = read_terragrunt_config(find_in_parent_folders("backend.hcl")).inputs.bucket
        prefix = "${basename(path_relative_to_include())}"
    }
}
```

Once again, terragrunt plan shouldn't see any difference ;-).

## Finishing the job

Using the same strategies, we are going to strip all variables still inside `dept-datascience/team-A/product1/product1-dev-zwindler/variables.tf` and factor them at various levels of our folders hierarchy.

First, I'm going to assume that we want, by default, all our resources to be deployed in western europe. This can of course be overriden, but most of the time it will be enough. So the values can be added in global.hcl file:

```hcl
cat > global.hcl <<EOF
inputs = {
    billing_account = "01AB34-CD56EF-78GH90"
    location = "EU"
    region = "europe-west1"
    zone = "europe-west1-b"
}
EOF
```

Then, the team name and owner name are going to be the same for all project beneath dept-datascience/team-A (again, it's overridable if need be):

```hcl
cat > dept-datascience/team-A/team.hcl <<EOF
inputs = {
    team" = "team_a"
    "owner" = "zwindler"
}
EOF
```

All projects from a given product are stored in the same folder in this example (dev and prod for product1). So, the folder variable has to be defined at `dept-datascience/team-A/product1` level.

```hcl
cat > dept-datascience/team-A/product1/product.hcl <<EOF
inputs = {
    folder_id = "folders/1039580298145"
}
EOF
```

team.hcl, product.hcl are new files to discover upward. Also, environment has to be deduced from directory name (like project_name). So we have to add this in our top-level terragrunt.hcl file in the inputs section:

```hcl
inputs = merge(
    read_terragrunt_config(find_in_parent_folders("global.hcl")).inputs,
    #add these 2 lines
    read_terragrunt_config(find_in_parent_folders("team.hcl")).inputs,
    read_terragrunt_config(find_in_parent_folders("product.hcl")).inputs,
    {
        project_name = "${basename(get_terragrunt_dir())}"
        #add this line
        environment = split("-", "${basename(path_relative_to_include())}")[1]
    }
)
```

In `dept-datascience/team-A/product1/product1-dev-zwindler/variables.tf`, replace all "defaults" by "type = string".

Plan will display no difference :)

## Is this over now?

At this point, there shouldn't be any variable left in the `dept-datascience/team-A/product1/product1-dev-zwindler`. All variables to deploy a project are either deduced or given at a higher level in the folders hierarchy.

But if you want to check if this really works, you can copy the `product1-dev-zwindler` to create a new environment (prod for example but this can be anything), and try to deploy it.

terragrunt plan should output a project similar in every point, with all the required variables.

```bash
cp dept-datascience/team-A/product1/product1-dev-zwindler/*.{tf,hcl} dept-datascience/team-A/product1/product1-prod-zwindler
cd dept-datascience/team-A/product1/product1-prod-zwindler

terragrunt plan
Terraform will perform the following actions:

  # module.project.google_project.project[0] will be created
  + resource "google_project" "project" {
      + auto_create_network = false
      + billing_account     = "01AB34-CD56EF-78GH90"
      + folder_id           = "1039580298145"
      + id                  = (known after apply)
      + labels              = {
          + "environment" = "prod"
          + "owner"       = "zwindler"
          + "team"        = "team_a"
        }
      + name                = "product1-prod-zwindler"
      + number              = (known after apply)
      + project_id          = "product1-prod-zwindler"
      + skip_delete         = false
    }

Plan: 1 to add, 0 to change, 0 to destroy.
```