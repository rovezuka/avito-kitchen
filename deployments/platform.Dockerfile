FROM golang:1.26-alpine AS build

WORKDIR /src

# Слой с зависимостями кешируется отдельно: пока go.mod и go.sum
# не менялись, повторная сборка не скачивает модули заново.
COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /out/platform ./cmd/platform

FROM alpine:3.20

RUN apk add --no-cache ca-certificates tzdata \
 && adduser -D -u 10001 app

COPY --from=build /out/platform /usr/local/bin/platform

USER app
EXPOSE 8080
ENTRYPOINT ["platform"]