# Input variable definitions
variable "app" {
  description = "Name of the application (ex. learn)"
  type        = string
}

variable "cluster_name" {
  description = "Optional override the generated cluster name"
  type        = string
  default     = null
  nullable    = true
}

variable "cluster_version" {
  description = "A version of this database cluster, this is so we can make multiple clusters in terraform when we need to do big migrations"
  type        = string
}

variable "cpus" {
  description = "Number of CPUs per database node."
  type        = number
  default     = 2
}

variable "db_name" {
  description = "Optional override of the generated database name (default is the value of app)"
  type        = string
  default     = null
  nullable    = true
}

variable "db_username" {
  description = "Optional override of the generated database username (default is the value of app)"
  type        = string
  default     = null
  nullable    = true
}


variable "facility" {
  description = "Name of the facility (ex. staging, techgoeshome)"
  type        = string
}

variable "k8s" {
  description = "Name of the application (k8s) cluster."
  type        = string
}

variable "namespace" {
  description = "The k8s namespace for resources"
  type        = string
}

variable "memory_gb" {
  description = "The amount of memory allocated to the pg database."
  type        = number
  default     =  4
  validation {
    condition = var.memory_gb > 0 && (var.memory_gb == 1 || pow(2, floor(log(var.memory_gb, 2))) == var.memory_gb)
    error_message = "must be a power of two."
  }
}

variable "node_count" {
  description = "The number of database instances."
  type = number
  default = 1
}

variable "pg_version" {
  description = "Version of Postgres to use.  Ex: 12, 11, 10, 9.6"
  type        = string
  default     = "17"
}

variable "vpc" {
  description = "Digital Ocean Virtual Private Cloud this database will run within."
  type        = string
}

variable "vpn" {
  description = "Name of the VPN that users can connect with."
  type        = string
}
