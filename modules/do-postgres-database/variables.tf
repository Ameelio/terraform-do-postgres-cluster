# Input variable definitions
variable "cluster_id" {
  description = "The cluster_id for the database cluster"
  type        = string
}

variable "cluster_host" {
  description = "The host of the db cluster"
  type        = string
}

variable "cluster_port" {
  description = "The TCP port the db cluster is listening on"
  type        = string
}

variable "cluster_version" {
  description = "A version of this database cluster, this is so we can make multiple clusters in terraform when we need to do big migrations"
  type        = string
}

variable "enable_replication" {
  description = "(Optional) Set to true to create the secrets needed to facilitate replication"
  type        = bool
  default     = false
  nullable    = true
}

variable "labels" {
  description = "K8s labels to apply to the secrets"
  type = map(string)
}

variable "k8s_prefix" {
  description = "(Optional) k8s prefix to apply to secret manifests (default is the value of username)"
  type        = string
  default     = null
  nullable    = true
}

variable "max_threads" {
  description = "Maximum number of threads to expose as 'MAX_THREADS'"
  type        = number
}

variable "name" {
  description = "The database name"
  type        = string
}

variable "namespace" {
  description = "The k8s namespace for resources"
  type        = string
}

variable "username" {
  description = "Database username (default is the value of name)"
  type        = string
  default     = null
  nullable    = true
}

