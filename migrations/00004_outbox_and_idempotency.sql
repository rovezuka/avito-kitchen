-- +goose Up
CREATE TABLE outbox (
                        id              bigserial PRIMARY KEY,
                        aggregate_type  text        NOT NULL,
                        aggregate_id    uuid        NOT NULL,
                        event_type      text        NOT NULL,
                        payload         jsonb       NOT NULL,
                        status          text        NOT NULL DEFAULT 'pending'
                            CHECK (status IN ('pending', 'sent', 'failed')),
                        attempts        integer     NOT NULL DEFAULT 0,
                        next_attempt_at timestamptz NOT NULL DEFAULT now(),
                        last_error      text,
                        created_at      timestamptz NOT NULL DEFAULT now(),
                        sent_at         timestamptz
);

-- Частичный индекс: воркер интересуется только неотправленными.
CREATE INDEX outbox_pending_idx ON outbox (next_attempt_at) WHERE status = 'pending';

CREATE TABLE idempotency_keys (
                                  id           bigserial PRIMARY KEY,
                                  customer_id  uuid        NOT NULL REFERENCES customers (id) ON DELETE CASCADE,
                                  key          text        NOT NULL,
                                  request_hash text        NOT NULL,
                                  order_id     uuid        REFERENCES orders (id) ON DELETE SET NULL,
                                  created_at   timestamptz NOT NULL DEFAULT now(),
                                  UNIQUE (customer_id, key)
);

-- +goose Down
DROP TABLE IF EXISTS idempotency_keys;
DROP TABLE IF EXISTS outbox;