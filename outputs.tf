
output "url" {
  description = "connection url for database clients, uses the blue instance if enabled, otherwise it uses the green instance"
  sensitive = true
  value = "postgres://${digitalocean_database_user.app_user.name}:${digitalocean_database_user.app_user.password}@${digitalocean_database_cluster.db_cluster.private_host}:${digitalocean_database_cluster.db_cluster.port}/${digitalocean_database_db.db.name}"
}
