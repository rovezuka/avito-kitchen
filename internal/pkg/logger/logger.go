package logger

import (
	"log/slog"
	"os"
)

// New создаёт структурный логгер.
// Локально — человекочитаемый текст, в остальных окружениях — JSON,
// который умеют разбирать системы сбора логов.
func New(level slog.Level, pretty bool) *slog.Logger {
	opts := &slog.HandlerOptions{Level: level}

	var h slog.Handler
	if pretty {
		h = slog.NewTextHandler(os.Stdout, opts)
	} else {
		h = slog.NewJSONHandler(os.Stdout, opts)
	}

	return slog.New(h)
}
