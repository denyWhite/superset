#!/bin/bash

set -e

TAG="$1"

if [ -z "$TAG" ]; then
  echo "Ошибка: Тег не указан"
  exit 1
fi

if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "Ошибка: Есть измененные файлы на проде. Изменения потеряются, зафиксируйте их. Деплой отменен."
  git status --short
  exit 1
fi

echo "Деплой версии: $TAG"

# Остановить приложение
docker compose -f docker-compose-non-dev.yml down

# Подтянуть все изменения и теги
git fetch origin --tags

# Проверить, существует ли тег
if ! git rev-parse "refs/tags/$TAG" >/dev/null 2>&1; then
  echo "Ошибка: Тег '$TAG' не существует"
  exit 1
fi

# Переключиться на тег (detached HEAD)
git checkout "$TAG"

# !!!В случае если нужно сделать `docker-compose build` до запуска.
# Делаем это вручную на сервере, так как это занимает больше 10 минут, что непозволимо для github-actions (таймаут выйдет)

# Запустить приложение
docker compose -f docker-compose-non-dev.yml up -d

echo "✅ Деплой успешно завершен. Запушенная версия: $TAG"
