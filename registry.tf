resource "yandex_container_registry" "app_registry" {
  name = "project-container-registry"

  labels = {
    environment = "production"
  }
}

resource "terraform_data" "build_and_push_image" {
  # Триггер: перезапускать скрипт, если изменился реестр или исходники приложения
  triggers_replace = [
    yandex_container_registry.app_registry.id,
    filemd5("./app.py"),
    filemd5("./Dockerfile"),
    filemd5("./docker-compose.yaml")
  ]

  provisioner "local-exec" {
    # Передаем ID созданного реестра в переменные окружения скрипта
    environment = {
      REGISTRY_ID = yandex_container_registry.app_registry.id
    }

    # Команды, которые выполнятся на вашем компьютере при terraform apply
    command = <<EOT
      yc iam create-token | docker login --username iam --password-stdin cr.yandex
      docker compose build
      docker compose push
    EOT
  }

  # Явно ждем создания самого реестра
  depends_on = [
    yandex_container_registry.app_registry
  ]
}