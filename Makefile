.DEFAULT_GOAL := help

# путь к БД для локального запуска goose (вне docker)
DB_DSN ?= postgres://kitchen:kitchen@localhost:5432/kitchen?sslmode=disable

.PHONY: help
help: ## показать список команд
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}'

.PHONY: up
up: ## поднять всё окружение
	docker compose up --build -d

.PHONY: down
down: ## погасить окружение
	docker compose down -v

.PHONY: logs
logs: ## смотреть логи
	docker compose logs -f

.PHONY: lint
lint: ## запустить линтер
	golangci-lint run ./...

.PHONY: test
test: ## запустить тесты
	go test -race -count=1 ./...

.PHONY: tidy
tidy: ## привести go.mod в порядок
	go mod tidy