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