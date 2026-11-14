import os
import socket
from http.server import BaseHTTPRequestHandler, HTTPServer
import pymysql

# Настройки подключения к MySQL из переменных окружения
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = int(os.getenv("DB_PORT", 3306))
DB_USER = os.getenv("DB_USER", "root")
DB_PASSWORD = os.getenv("DB_PASSWORD", "password")
DB_NAME = os.getenv("DB_NAME", "test_db")

def get_db_connection():
    return pymysql.connect(
        host=DB_HOST,
        port=DB_PORT,
        user=DB_USER,
        password=DB_PASSWORD,
        database=DB_NAME,
        cursorclass=pymysql.cursors.DictCursor,
        autocommit=True
    )

def init_db():
    """Создает таблицу для хранения визитов, если её ещё нет."""
    conn = get_db_connection()
    with conn.cursor() as cursor:
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS visits (
                id INT AUTO_INCREMENT PRIMARY KEY,
                visited_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)
    conn.close()

class SimpleHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        # Игнорируем автоматический запрос браузера за иконкой сайта
        if self.path == "/favicon.ico":
            self.send_response(404)
            self.end_headers()
            return

        hostname = socket.gethostname()

        try:
            conn = get_db_connection()
            with conn.cursor() as cursor:
                # Записываем новый визит
                cursor.execute("INSERT INTO visits () VALUES ()")
                # Считаем общее количество записей
                cursor.execute("SELECT COUNT(*) AS total FROM visits")
                result = cursor.fetchone()
                total_visits = result["total"]
            conn.close()

            self.send_response(200)
            self.send_header("Content-type", "text/html; charset=utf-8")
            self.end_headers()
            response_text = (
                f"<h1>Python + MySQL работает!</h1>"
                f"<p>Hostname: <b>{hostname}</b></p>"
                f"<p>База данных: <b>{DB_NAME}</b> ({DB_HOST})</p>"
                f"<p>Всего обращений к БД: <b>{total_visits}</b></p>"
            )
        except Exception as e:
            self.send_response(500)
            self.send_header("Content-type", "text/html; charset=utf-8")
            self.end_headers()
            response_text = f"<h1>Ошибка подключения к MySQL</h1><pre>{e}</pre>"

        self.wfile.write(response_text.encode("utf-8"))

if __name__ == "__main__":
    try:
        init_db()
        print("Таблица в MySQL успешно проверена/создана.")
    except Exception as e:
        print(f"Предупреждение при старте (БД пока недоступна): {e}")

    server_address = ("0.0.0.0", 8080)
    httpd = HTTPServer(server_address, SimpleHandler)
    print("Сервер запущен на http://0.0.0 ...")
    httpd.serve_forever()