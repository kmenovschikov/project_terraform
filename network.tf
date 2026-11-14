# 1. Создание Virtual Private Cloud (VPC)
resource "yandex_vpc_network" "main_vpc" {
  name = "project-vpc"
}

# 2. Создание подсетей в разных зонах доступности
resource "yandex_vpc_subnet" "subnet_a" {
  name           = "subnet-ru-central1-a"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.main_vpc.id
  v4_cidr_blocks = ["10.10.1.0/24"]
}

resource "yandex_vpc_subnet" "subnet_d" {
  name           = "subnet-ru-central1-d"
  zone           = "ru-central1-d"
  network_id     = yandex_vpc_network.main_vpc.id
  v4_cidr_blocks = ["10.10.2.0/24"]
}

# 3. Настройка группы безопасности для VM (порты 22, 80, 443)
resource "yandex_vpc_security_group" "vm_sg" {
  name        = "vm-security-group"
  description = "Правила фаервола для виртуальных машин (SSH, HTTP, HTTPS)"
  network_id  = yandex_vpc_network.main_vpc.id

  ingress {
    protocol       = "TCP"
    description    = "Разрешить SSH"
    port           = 22
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    description    = "Разрешить HTTP"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    description    = "Разрешить HTTPS"
    port           = 443
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "ANY"
    description    = "Разрешить весь исходящий трафик"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# Группа безопасности для MySQL (принимает трафик только от наших VM)
resource "yandex_vpc_security_group" "db_sg" {
  name       = "mysql-security-group"
  network_id = yandex_vpc_network.main_vpc.id

  ingress {
    protocol          = "TCP"
    description       = "Доступ к MySQL из группы безопасности VM"
    port              = 3306
    security_group_id = yandex_vpc_security_group.vm_sg.id
  }
}
