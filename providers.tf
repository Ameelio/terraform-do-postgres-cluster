# ################################################################################
# Configures resource providers for use with terraform.
# If you change this file, make should run terraform init -chdir='terraform'
# ################################################################################

terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "~> 2.0"
    }

    # aws = {
    #   source  = "hashicorp/aws"
    #   version = "~> 4.0"
    # }
    #
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4.0"
    }

    # null = {
    #   source = "hashicorp/null"
    #   version = "~> 3.2.1"
    # }

  }

  required_version = "~> 1.6.5"
}

# Configure the AWS Provider
# provider "aws" {
#   region = var.aws_region
# }

# Set the variable value in *.tfvars file
# or using -var="do_token=..." CLI option
# variable "digitalocean_access_token" {
#   type        = string
#   description = "Digital Ocean API access token. Suggest env var TF_VAR_digitalocean_access_token"
# }
#
# # Configure the DigitalOcean Provider
# provider "digitalocean" {
#   token = var.digitalocean_access_token
# }

