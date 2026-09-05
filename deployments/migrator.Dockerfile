# Отдельный крошечный образ, который умеет только гонять миграции.
# Нужен, чтобы `docker compose up` работал у любого человека,
# у которого не установлен goose локально.
FROM golang:1.26-alpine AS build
RUN go install github.com/pressly/goose/v3/cmd/goose@latest

FROM alpine:3.20
RUN apk add --no-cache ca-certificates
COPY --from=build /go/bin/goose /usr/local/bin/goose
WORKDIR /migrations
ENTRYPOINT ["goose"]