output "vm_external_ips" {
  description = "Внешние IP-адреса созданных виртуальных машин"
  value       = yandex_compute_instance.app_vms[*].network_interface[0].nat_ip_address
}

output "mysql_fqdn" {
  description = "Внутренний адрес для подключения к БД MySQL"
  value       = yandex_mdb_mysql_cluster.mysql_cluster.host[0].fqdn
}

output "container_registry_id" {
  description = "ID реестра контейнеров (используется в пути image:tag)"
  value       = yandex_container_registry.app_registry.id
}
