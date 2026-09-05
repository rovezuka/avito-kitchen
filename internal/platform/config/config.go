package config

import (
	"fmt"
	"log/slog"
	"os"
	"strconv"
	"time"
)

// Config — вся конфигурация сервиса. Читается один раз при старте.
type Config struct {
	Env             string
	LogLevel        slog.Level
	HTTPPort        string
	ShutdownTimeout time.Duration
	Postgres        Postgres
}

type Postgres struct {
	DSN      string
	MaxConns int32
}

// Load читает конфигурацию из переменных окружения.
// Отсутствие обязательной переменной — ошибка на старте, а не при первом запросе.
func Load() (Config, error) {
	dsn := os.Getenv("POSTGRES_DSN")
	if dsn == "" {
		return Config{}, fmt.Errorf("POSTGRES_DSN is required")
	}

	maxConns, err := envInt("POSTGRES_MAX_CONNS", 10)
	if err != nil {
		return Config{}, err
	}

	shutdownTimeout, err := envDuration("SHUTDOWN_TIMEOUT", 10*time.Second)
	if err != nil {
		return Config{}, err
	}

	level, err := parseLevel(envString("LOG_LEVEL", "info"))
	if err != nil {
		return Config{}, err
	}

	return Config{
		Env:             envString("APP_ENV", "local"),
		LogLevel:        level,
		HTTPPort:        envString("HTTP_PORT", "8080"),
		ShutdownTimeout: shutdownTimeout,
		Postgres: Postgres{
			DSN:      dsn,
			MaxConns: int32(maxConns),
		},
	}, nil
}

func envString(key, def string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return def
}

func envInt(key string, def int) (int, error) {
	raw := os.Getenv(key)
	if raw == "" {
		return def, nil
	}
	v, err := strconv.Atoi(raw)
	if err != nil {
		return 0, fmt.Errorf("%s: %w", key, err)
	}
	return v, nil
}

func envDuration(key string, def time.Duration) (time.Duration, error) {
	raw := os.Getenv(key)
	if raw == "" {
		return def, nil
	}
	v, err := time.ParseDuration(raw)
	if err != nil {
		return 0, fmt.Errorf("%s: %w", key, err)
	}
	return v, nil
}

func parseLevel(raw string) (slog.Level, error) {
	var level slog.Level
	if err := level.UnmarshalText([]byte(raw)); err != nil {
		return 0, fmt.Errorf("LOG_LEVEL: %w", err)
	}
	return level, nil
}
