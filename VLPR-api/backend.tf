# The block below configures Terraform to use the 'remote' backend with Terraform Cloud.
# For more information, see https://www.terraform.io/docs/backends/types/remote.html
terraform {
  cloud {
    organization = "GlobalSoftwareHouse"

    workspaces {
      name = "VLPR-api"
    }
  }
}