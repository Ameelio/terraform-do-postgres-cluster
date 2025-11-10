data "digitalocean_vpc" "vpc" {
  name = var.vpc
}

# data items for firewall rules
data "digitalocean_droplet" "tailscale_subnet_router" {
  name = var.vpn
}

data "digitalocean_kubernetes_cluster" "k8s_cluster" {
  name = var.k8s
}

locals {
  cluster_name  = coalesce(var.cluster_name, "db-postgresql-${data.digitalocean_vpc.vpc.region}-${var.facility}-${var.app}-${var.cluster_version}")
  db_name       = coalesce(var.db_name, var.app)
  db_username   = coalesce(var.db_username, var.app)
  size          = "db-s-${var.cpus}vcpu-${var.memory_gb}gb"
  tags          = ["db", var.facility, var.app, var.cluster_version]
}

### Postgres Cluster
resource "digitalocean_database_cluster" "db_cluster" {
  engine               = "pg"
  name                 = local.cluster_name
  node_count           = var.node_count
  private_network_uuid = data.digitalocean_vpc.vpc.id
  region               = data.digitalocean_vpc.vpc.region
  size                 = local.size
  tags                 = local.tags
  version              = var.pg_version
}

resource "digitalocean_database_db" "db" {
  cluster_id  = digitalocean_database_cluster.db_cluster.id
  name        = local.db_name
}

resource "digitalocean_database_user" "app_user" {
  cluster_id  = digitalocean_database_cluster.db_cluster.id
  name        = local.db_username
}

resource "digitalocean_database_firewall" "firewall" {
  cluster_id  = digitalocean_database_cluster.db_cluster.id

  # Tailscale subnet router
  rule {
    type  = "droplet"
    value = data.digitalocean_droplet.tailscale_subnet_router.id
  }

  # Kubernetes cluster where Canvas runs
  rule {
    type = "k8s"
    value = data.digitalocean_kubernetes_cluster.k8s_cluster.id
  }
}

resource "kubernetes_secret" "db" {
  metadata {
    labels = {
      app = var.app
    }
    name = "${var.app}-pg-secrets-${var.cluster_version}"
    namespace = var.namespace
  }
  type = "Opaque"
  data = {
    "ADMIN_DATABASE_URL" = digitalocean_database_cluster.db_cluster.private_uri
    "DATABASE_URL" = "postgres://${digitalocean_database_user.app_user.name}:${digitalocean_database_user.app_user.password}@${digitalocean_database_cluster.db_cluster.private_host}:${digitalocean_database_cluster.db_cluster.port}/${digitalocean_database_db.db.name}"
    # Legacy ENV Variables remove once every instance is on a cluster > 20250326
    "CANVAS_DB_HOSTNAME" = digitalocean_database_cluster.db_cluster.private_host
    "CANVAS_DB_PUBLIC_HOSTNAME" = digitalocean_database_cluster.db_cluster.host
    "CANVAS_DB_PORT" = digitalocean_database_cluster.db_cluster.port
    "CANVAS_DB_USERNAME" = digitalocean_database_user.app_user.name
    "CANVAS_DB_PASSWORD" = digitalocean_database_user.app_user.password
    "CANVAS_DB_TIMEOUT" = "5000"

    # threads and pools in the client should match this number.
    # The number of available connections is (25 * memory_gb - 3) * node_count
    # The total number of connections that will be made are: theads * workers * replicas.
    # A good rule of thumb would be keeping the replicas * workers under 22, while setting
    # the pool and trhead size to memory size. (You don't want a thread waiting for a free connection)
    "MAX_THREADS" = "${var.memory_gb}"
  }
}

resource "kubernetes_secret" "replication_target" {
  metadata {
    labels = {
      app = var.app
    }
    name = "${var.app}-pg-replication-target-secrets-${var.cluster_version}"
    namespace = var.namespace
  }
  type = "Opaque"
  data = {
    "REPLICATION_TARGET_URL" = "postgres://${digitalocean_database_cluster.db_cluster.user}:${digitalocean_database_cluster.db_cluster.password}@${digitalocean_database_cluster.db_cluster.private_host}:${digitalocean_database_cluster.db_cluster.port}/${digitalocean_database_db.db.name}"
  }
}

resource "kubernetes_secret" "replication_src" {
  metadata {
    labels = {
      app = var.app
    }
    name = "${var.app}-pg-replication-src-secrets-${var.cluster_version}"
    namespace = var.namespace
  }
  type = "Opaque"
  data = {
    "REPLICATION_SOURCE_URL" = "postgres://${digitalocean_database_cluster.db_cluster.user}:${digitalocean_database_cluster.db_cluster.password}@${digitalocean_database_cluster.db_cluster.private_host}:${digitalocean_database_cluster.db_cluster.port}/${digitalocean_database_db.db.name}"
  }
}
