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

variable "databases" {
  description = <<EOT
    A map of pg_clusters, the key should be
    a unique string, recommend matching the cluster
    version.
    The value is an object:
    {
      enable_re-plication: Set to true to generate replication user secrets.
      instance: Instance to label the secret manifests, defaults to the database name.
      k8s_prefix: Prefix for secret manifest names, defaults to the database username.
      name: Name of the database.
      username: Name of the database owner, defaults to the database name.
    }
  EOT

  type = map(object({
    enable_replication = optional(bool, false)
    instance = optional(string, null)
    k8s_prefix = optional(string, null)
    name = string
    username = optional(string, null)
  }))

  default   = null
  nullable  = true
}

variable "instance" {
  description = "Name of the instance (ex. staging, techgoeshome)"
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

variable "tier" {
  description = "Tier size of the postgres node. Ex: 's'"
  type        = string
  default     = "s"
}

variable "vpc" {
  description = "Digital Ocean Virtual Private Cloud this database will run within."
  type        = string
}

variable "vpn" {
  description = "Name of the VPN that users can connect with."
  type        = string
}
