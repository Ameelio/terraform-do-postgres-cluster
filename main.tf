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
  cluster_name  = coalesce(
    var.cluster_name,
      join("-", [
        "db-postgresql",
        data.digitalocean_vpc.vpc.region,
        var.instance,
        var.app,
        var.cluster_version
      ])
  )

  default_database = {
    "${var.app}" = {
      enable_replication  = false
      instance            = var.instance
      k8s_prefix          = var.app
      name                = var.app
      username            = var.app
    }
  }

  databases = coalesce(var.databases, local.default_database)

  labels = {
    "app.kubernetes.io/component"   = "database"
    "app.kubernetes.io/instance"    = var.instance
    "app.kubernetes.io/managed-by"  = "terraform"
    "app.kubernetes.io/name"        = "postgres"
    "app.kubernetes.io/part-of"     = var.app
    "app.kubernetes.io/version"     = "${var.pg_version}"
  }

  # threads and pools in the client should match this number.
  # The number of available connections is (25 * memory_gb - 3) * node_count
  # The total number of connections that will be made are: theads * workers * replicas.
  # A good rule of thumb would be keeping the replicas * workers under 22, while setting
  # the pool and trhead size to memory size. (You don't want a thread waiting for a free connection)
  max_threads   = var.memory_gb
  size          = "db-${coalesce(var.tier, "s")}-${var.cpus}vcpu-${var.memory_gb}gb"
  tags          = compact(["db", var.instance, var.app, var.cluster_version])
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

resource "kubernetes_secret" "cluster" {
  metadata {
    labels = local.labels
    name = "${local.cluster_name}-pg-secrets"
    namespace = var.namespace
  }

  type = "Opaque"

  data = {
    "PGDATABASE" = "${digitalocean_database_cluster.db_cluster.database}"
    "PGHOST"     = "${digitalocean_database_cluster.db_cluster.private_host}"
    "PGPORT"     = "${digitalocean_database_cluster.db_cluster.port}"
    "PGUSER"     = "${digitalocean_database_cluster.db_cluster.user}"
    "PGPASSWORD" = "${digitalocean_database_cluster.db_cluster.password}"
  }

}

module "database" {
  source              = "./modules/do-postgres-database"

  for_each            = local.databases

  cluster_id          = digitalocean_database_cluster.db_cluster.id
  cluster_host        = digitalocean_database_cluster.db_cluster.private_host
  cluster_port        = digitalocean_database_cluster.db_cluster.port
  cluster_version     = var.cluster_version

  labels              = merge(local.labels, {
    "app.kubernetes.io/instance" = coalesce(each.value.instance, var.instance)
  })

  enable_replication  = coalesce(each.value.enable_replication, false)
  k8s_prefix          = coalesce(each.value.k8s_prefix, each.value.username, each.value.name)
  max_threads         = local.max_threads
  name                = each.key
  namespace           = var.namespace
  username            = coalesce(each.value.username, each.value.name)
}

