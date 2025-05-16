#!/bin/bash

# Путь к лог-файлу
LOG_FILE="/var/log/monitoring.log"
# Имя процесса для мониторинга
PROCESS_NAME="test"
# URL для проверки
MONITORING_URL="https://test.com/monitoring/test/api"
# Файл для хранения предыдущего PID
PID_FILE="/var/run/test_monitor.pid"

# Функция логирования
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Проверка существования лог-файла, создание если отсутствует
if [ ! -f "$LOG_FILE" ]; then
    touch "$LOG_FILE"
    chmod 644 "$LOG_FILE"
fi

## Получение текущего PID процесса по его имени
# -o: возвращает родительский PID
CURRENT_PID=$(pgrep -o "$PROCESS_NAME")

## Проверка, запущен ли процесс
# Проверяет, пустая ли строка CURRENT_PID:
# -n "$CURRENT_PID": Возвращает true, если строка не пустая, то есть процесс test запущен.
if [ -n "$CURRENT_PID" ]; then
    ## Чтение предыдущего PID
    # Проверяет, существует ли файл PID_FILE:
    # Если существует, читает сохраненный PID в переменную PREV_PID с помощью cat.
    # Если не существует, устанавливает PREV_PID как пустую строку.
    if [ -f "$PID_FILE" ]; then
        PREV_PID=$(cat "$PID_FILE")
    else
        PREV_PID=""
    fi

    ## Проверка на перезапуск процесса
    # Сравнивает текущий PID с предыдущим:
    # Если они различаются (!=), это означает, что процесс был перезапущен (или запущен впервые).
    # Записывает в лог сообщение о перезапуске с новым PID.
    # Сохраняет текущий PID в PID_FILE с помощью echo ... >, перезаписывая файл.
    if [ "$CURRENT_PID" != "$PREV_PID" ]; then
        log_message "Process $PROCESS_NAME restarted with new PID: $CURRENT_PID"
        echo "$CURRENT_PID" > "$PID_FILE"
    fi

    ## Отправка HTTPS-запроса
    # Отправляет HTTPS-запрос к MONITORING_URL с помощью curl:
    # --silent: Подавляет вывод прогресса.
    # --fail: Возвращает ненулевой код выхода при HTTP-ошибках (например, 404, 500).
    # > /dev/null: Перенаправляет вывод команды в /dev/null, так как нам не нужен результат запроса.
    # Если запрос успешен, логируется сообщение Monitoring server check successful.
    # Если запрос не удался (сервер недоступен или вернул ошибку), логируется Monitoring server unavailable.
    if curl --silent --fail "$MONITORING_URL" > /dev/null; then
        log_message "Monitoring server check successful"
    else
        log_message "Monitoring server unavailable"
    fi
# Если процесс test не запущен (CURRENT_PID пустой), записывает в лог сообщение Process test is not running.
else
    log_message "Process $PROCESS_NAME is not running"
fi