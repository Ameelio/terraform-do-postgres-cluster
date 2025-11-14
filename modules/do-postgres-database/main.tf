locals {
  username = coalesce(var.username, var.name)
  k8s_prefix = coalesce(var.k8s_prefix, var.username)
}

resource "digitalocean_database_db" "db" {
  cluster_id  = var.cluster_id
  name        = var.name
}

resource "digitalocean_database_user" "app_user" {
  cluster_id  = var.cluster_id
  name        = local.username
}

resource "kubernetes_secret" "app_user" {
  metadata {
    labels = var.labels
    name = "${local.k8s_prefix}-pg-secrets-${var.cluster_version}"
    namespace = var.namespace
  }
  type = "Opaque"
  data = {
    # Most web apps look for DATABASE_URL in their environments.
    "DATABASE_URL" = "postgres://${digitalocean_database_user.app_user.name}:${digitalocean_database_user.app_user.password}@${var.cluster_host}:${var.cluster_port}/${digitalocean_database_db.db.name}"

    # psql can use these environment variables.
    "PGDATABASE" = "${digitalocean_database_db.db.name}"
    "PGHOST"     = "${var.cluster_host}"
    "PGPORT"     = "${var.cluster_port}"
    "PGUSER"     = "${digitalocean_database_user.app_user.name}"
    "PGPASSWORD" = "${digitalocean_database_user.app_user.password}"

    "MAX_THREADS" = "${var.max_threads}"
  }
}

resource "kubernetes_secret" "replication_target" {
  count = var.enable_replication ? 1 : 0

  metadata {
    labels = var.labels
    name = "${local.k8s_prefix}-pg-replication-target-secrets-${var.cluster_version}"
    namespace = var.namespace
  }
  type = "Opaque"
  data = {
    "REPLICATION_TARGET_DATABASE_URL" = "postgres://${digitalocean_database_user.app_user.name}:${digitalocean_database_user.app_user.password}@${var.cluster_host}:${var.cluster_port}/${digitalocean_database_db.db.name}"
  }
}

resource "kubernetes_secret" "replication_src" {
  count = var.enable_replication ? 1 : 0

  metadata {
    labels = var.labels
    name = "${local.k8s_prefix}-pg-replication-src-secrets-${var.cluster_version}"
    namespace = var.namespace
  }
  type = "Opaque"
  data = {
    "REPLICATION_SOURCE_URL" = "postgres://${digitalocean_database_user.app_user.name}:${digitalocean_database_user.app_user.password}@${var.cluster_host}:${var.cluster_port}/${digitalocean_database_db.db.name}"
  }
}
