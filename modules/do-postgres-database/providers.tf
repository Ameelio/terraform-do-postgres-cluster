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
  }
}
