resource "yandex_mdb_mysql_cluster" "mysql_cluster" {
  name               = "project-mysql-cluster"
  environment        = "PRESTABLE"
  network_id         = yandex_vpc_network.main_vpc.id
  version            = "8.0"
  security_group_ids = [yandex_vpc_security_group.db_sg.id]

  resources {
    resource_preset_id = "s2.micro" # Минимальный конфиг для экономии
    disk_type_id       = "network-hdd"
    disk_size          = 10
  }

  host {
    zone      = "ru-central1-a"
    subnet_id = yandex_vpc_subnet.subnet_a.id
  }
}

resource "yandex_mdb_mysql_database" "db" {
  cluster_id = yandex_mdb_mysql_cluster.mysql_cluster.id
  name       = var.db_name
}

resource "yandex_mdb_mysql_user" "user" {
  cluster_id = yandex_mdb_mysql_cluster.mysql_cluster.id
  name       = var.db_user
  password   = local.db_password

  permission {
    database_name = yandex_mdb_mysql_database.db.name
    roles         = ["ALL"]
  }
}


#### PASSWORD

# 1. Находим секрет по его имени в облаке
data "yandex_lockbox_secret" "db_secret" {
  name = "mysql-db-secret"
}

# 2. Получаем последнюю версию этого секрета
data "yandex_lockbox_secret_version" "db_secret_ver" {
  secret_id = data.yandex_lockbox_secret.db_secret.id
}

# 3. Извлекаем значение по ключу "password" в локальную переменную
locals {
  db_password = [
    for entry in data.yandex_lockbox_secret_version.db_secret_ver.entries :
    entry.text_value if entry.key == "password"
  ][0]
}
