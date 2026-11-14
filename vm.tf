
data "yandex_compute_image" "ubuntu" {
  family = "ubuntu-24-04-lts"
}

# Создание VM
resource "yandex_compute_instance" "app_vms" {
  name        = "app-vm-1"
  platform_id = "standard-v3"
  zone        = "ru-central1-a"

  service_account_id = "aje5ilun2o0nmtm5lgb4"

  # Виртуальные машины не начнут создаваться, пока образ не запушится в реестр
  depends_on = [
    terraform_data.build_and_push_image,
    yandex_mdb_mysql_database.db,
    yandex_mdb_mysql_user.user
  ]
  
  resources {
    cores         = 2
    memory        = 2
    core_fraction = 50
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      type     = "network-hdd"
      size     = 10
    }
  }


  network_interface {
    subnet_id          = yandex_vpc_subnet.subnet_a.id
    nat                = true
    # Привязка группы безопасности (порты 22, 80, 443) к VM
    security_group_ids = [yandex_vpc_security_group.vm_sg.id]
  }

  
    metadata = {
    user-data = templatefile("./cloud-init.yml", {
      ssh_key         = local.ssh_key
      compose_content = file("./docker-compose.yaml")
      registry_id     = yandex_container_registry.app_registry.id
      db_host         = yandex_mdb_mysql_cluster.mysql_cluster.host[0].fqdn
      db_user         = var.db_user
      db_password     = local.db_password
      db_name         = var.db_name
    })
  }

}

locals {
  ssh_key = file(pathexpand("~/.ssh/id_rsa.pub"))
}

