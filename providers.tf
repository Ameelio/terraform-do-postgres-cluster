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

    local = {
      source  = "hashicorp/local"
      version = "~> 2.4.0"
    }

  }

  required_version = "~> 1.14.0"
}
