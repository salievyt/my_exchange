.PHONY: help deploy build migrate setwebhook backup restore logs shell psql \
        backup-db restore-db healthcheck status restart clean

DOCKER_COMPOSE = docker compose
DOCKER_EXEC    = docker compose exec -T
DOCKER_RUN     = docker compose run --rm

# ──────────────────────────────────────────────
# 🚀  Основные команды
# ──────────────────────────────────────────────

help: ## Показать эту справку
	@echo ""
	@echo "  🚀  My Exchange — Makefile"
	@echo "  ─────────────────────────────────"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| sort \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ""

deploy: ## Полный деплой: git pull → build → migrate → setwebhook → healthcheck
	@echo ""
	@echo "  ╔══════════════════════════════════════╗"
	@echo "  ║   🚀  My Exchange — Deploy           ║"
	@echo "  ╚══════════════════════════════════════╝"
	@echo ""
	$(MAKE) git-pull
	$(MAKE) build
	$(MAKE) migrate
	$(MAKE) setwebhook
	$(MAKE) healthcheck
	$(MAKE) status
	@echo ""
	@echo "  ✅  Деплой завершён!"
	@echo ""

git-pull: ## Получить последние изменения из git
	@echo "  📥  Pulling latest changes..."
	@git pull --ff-only
	@echo ""

build: ## Собрать Docker-образы (с кэшем)
	@echo "  🏗️  Building Docker images..."
	$(DOCKER_COMPOSE) build
	@echo ""

build-nc: ## Собрать Docker-образы без кэша (полная пересборка)
	@echo "  🏗️  Rebuilding Docker images (no cache)..."
	$(DOCKER_COMPOSE) build --no-cache
	@echo ""

up: ## Запустить все сервисы в фоне
	@echo "  🚀  Starting all services..."
	$(DOCKER_COMPOSE) up -d
	@echo ""

restart: ## Перезапустить все сервисы
	@echo "  🔄  Restarting all services..."
	$(DOCKER_COMPOSE) restart
	@echo ""

migrate: ## Накатить миграции Django
	@echo "  📦  Running migrations..."
	$(DOCKER_EXEC) backend python manage.py migrate --noinput
	@echo ""

makemigrations: ## Создать новые миграции (локально)
	@echo "  📝  Creating migrations..."
	python manage.py makemigrations
	@echo ""

setwebhook: ## Установить вебхук Telegram бота
	@echo "  🤖  Setting Telegram bot webhook..."
	$(DOCKER_RUN) bot
	@echo ""

delete-webhook: ## Удалить вебхук Telegram бота
	@echo "  🗑️  Deleting Telegram bot webhook..."
	$(DOCKER_RUN) bot python manage.py setwebhook --delete
	@echo ""

collectstatic: ## Собрать статику Django
	@echo "  🎨  Collecting static files..."
	$(DOCKER_EXEC) backend python manage.py collectstatic --noinput --clear
	@echo ""

init-data: ## Инициализировать данные по умолчанию (валюты, админ)
	@echo "  📊  Initializing default data..."
	$(DOCKER_EXEC) backend python manage.py init_data
	@echo ""

# ──────────────────────────────────────────────
# 🩺  Healthcheck
# ──────────────────────────────────────────────

healthcheck: ## Проверить здоровье всех сервисов
	@echo "  🩺  Healthcheck..."
	@echo ""
	@echo "  ── Services ──"
	@$(DOCKER_COMPOSE) ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null \
		|| $(DOCKER_COMPOSE) ps
	@echo ""
	@echo "  ── HTTP Endpoints ──"
	@echo -n "     Landing page    : "; \
		curl -s -o /dev/null -w "%{http_code}" --max-time 5 http://localhost:8000/ \
		|| echo "unreachable"; \
		echo ""
	@echo -n "     API requests    : "; \
		curl -s -o /dev/null -w "%{http_code}" --max-time 5 http://localhost:8000/api/requests/ \
		|| echo "unreachable"; \
		echo ""
	@echo -n "     Admin           : "; \
		curl -s -o /dev/null -w "%{http_code}" --max-time 5 http://localhost:8000/admin/ \
		|| echo "unreachable"; \
		echo ""
	@echo ""
	@echo "  ── Telegram Bot ──"
	@TOKEN=$$($(DOCKER_EXEC) backend python manage.py shell -c \
		"from apps.bot.models import BotConfig; \
		 c = BotConfig.objects.filter(key='BOT_TOKEN').first(); \
		 print(c.value[:5] if c and c.value else '')" 2>/dev/null); \
	if [ -n "$$TOKEN" ]; then \
		echo -n "     Webhook status  : "; \
		BOT_TOKEN=$$($(DOCKER_EXEC) backend python manage.py shell -c \
			"from apps.bot.models import BotConfig; \
			 c = BotConfig.objects.filter(key='BOT_TOKEN').first(); \
			 print(c.value if c and c.value else '')" 2>/dev/null); \
		if [ -n "$$BOT_TOKEN" ]; then \
			curl -s "https://api.telegram.org/bot$$BOT_TOKEN/getWebhookInfo" \
				--max-time 5 | python3 -c \
				"import sys,json; \
				 d=json.load(sys.stdin); \
				 u=d.get('result',{}).get('url',''); \
				 e=d.get('result',{}).get('last_error_message',''); \
				 print(f'URL: {u}'); \
				 print(f'     Errors: {e}' if e else '     No errors'); \
				 print(f'     Pending: {d.get(\"result\",{}).get(\"pending_update_count\",0)}')" \
			2>/dev/null || echo "     (API unreachable)"; \
		else \
			echo "     (BOT_TOKEN not configured)"; \
		fi; \
	else \
		echo "     (BOT_TOKEN not configured)"; \
	fi
	@echo ""

status: ## Показать статус всех сервисов
	@$(DOCKER_COMPOSE) ps
	@echo ""
	@echo "  ── Resource usage ──"
	@docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" 2>/dev/null \
		|| echo "  (docker stats not available)"

logs: ## Смотреть логи всех сервисов (Ctrl+C для выхода)
	$(DOCKER_COMPOSE) logs -f --tail=50

logs-backend: ## Смотреть логи только backend
	$(DOCKER_COMPOSE) logs -f --tail=50 backend

logs-bot: ## Смотреть логи бота (вебхук)
	$(DOCKER_COMPOSE) logs -f --tail=50 bot

# ──────────────────────────────────────────────
# 🐚  Shell / Database
# ──────────────────────────────────────────────

shell: ## Открыть Django shell
	$(DOCKER_COMPOSE) exec backend python manage.py shell

shell-plain: ## Открыть bash внутри контейнера backend
	$(DOCKER_COMPOSE) exec backend bash

psql: ## Открыть psql внутри контейнера БД
	$(DOCKER_COMPOSE) exec db psql -U postgres -d my_exchange

createsuperuser: ## Создать суперпользователя Django
	$(DOCKER_COMPOSE) exec backend python manage.py createsuperuser

# ──────────────────────────────────────────────
# 💾  Backup / Restore
# ──────────────────────────────────────────────

BACKUP_DIR   ?= backups
BACKUP_FILE  ?= $(BACKUP_DIR)/my_exchange_$(shell date +%Y%m%d_%H%M%S).sql

backup: ## Создать дамп базы данных
	@mkdir -p $(BACKUP_DIR)
	@echo "  💾  Backing up database to $(BACKUP_FILE)..."
	$(DOCKER_EXEC) db pg_dump -U postgres --clean --if-exists my_exchange > $(BACKUP_FILE)
	@gzip -f $(BACKUP_FILE)
	@echo "  ✅  Backup: $(BACKUP_FILE).gz  ($(shell du -h $(BACKUP_FILE).gz | cut -f1))"
	@echo ""

restore: ## Восстановить базу из последнего дампа FILE=путь
ifndef FILE
	$(error Usage: $(MAKE) restore FILE=backups/my_exchange_20250301_120000.sql.gz)
endif
	@echo "  ♻️   Restoring database from $(FILE)..."
	@if echo "$(FILE)" | grep -q '\.gz$$'; then \
		gunzip -c $(FILE) | $(DOCKER_EXEC) -T db psql -U postgres my_exchange; \
	else \
		cat $(FILE) | $(DOCKER_EXEC) -T db psql -U postgres my_exchange; \
	fi
	@echo "  ✅  Restore completed!"
	@echo "  ⚠️   Don't forget to restart: $(MAKE) restart"

list-backups: ## Показать список доступных бэкапов
	@ls -lh $(BACKUP_DIR)/ 2>/dev/null || echo "  (no backups found)"

# ──────────────────────────────────────────────
# 🧹  Cleanup
# ──────────────────────────────────────────────

stop: ## Остановить все сервисы
	$(DOCKER_COMPOSE) stop

down: ## Остановить и удалить контейнеры (сохранить volumes)
	$(DOCKER_COMPOSE) down

clean: ## ❗ Остановить всё и удалить volumes (потеря данных!)
	@echo "  ⚠️   This will DELETE ALL DATA! Continue? [y/N] "
	@read -r ans; \
	if [ "$$ans" = "y" ] || [ "$$ans" = "Y" ]; then \
		$(DOCKER_COMPOSE) down -v; \
		echo "  ✅  Cleaned up."; \
	fi

prune: ## Docker system prune (очистить неиспользуемые ресурсы)
	docker system prune -f
