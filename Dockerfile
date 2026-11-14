# ==========================================
# Этап 1: Сборщик (Builder)
# ==========================================
FROM python:3.12-slim AS builder

WORKDIR /build

# Устанавливаем системные пакеты, нужные для компиляции зависимостей (например, cryptography)
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    libssl-dev \
    libffi-dev \
    && rm -rf /var/lib/apt/lists/*

# Создаем изолированное виртуальное окружение
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Устанавливаем Python-зависимости внутрь виртуального окружения
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# ==========================================
# Этап 2: Финальный легкий образ (Runtime)
# ==========================================
FROM python:3.12-slim

WORKDIR /app

# Отключаем буферизацию вывода для корректного отображения логов в Docker
ENV PYTHONUNBUFFERED=1
ENV PATH="/opt/venv/bin:$PATH"

# Копируем ТОЛЬКО готовое виртуальное окружение из первого этапа (без gcc и кэша)
COPY --from=builder /opt/venv /opt/venv

# Создаем непривилегированного пользователя для безопасности
RUN useradd -m appuser
USER appuser

# Копируем код приложения
COPY --chown=appuser:appuser app.py .

EXPOSE 8080

CMD ["python", "app.py"]
