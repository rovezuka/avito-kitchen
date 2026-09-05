-- +goose Up
CREATE SEQUENCE order_public_number_seq START 100000;

CREATE TABLE orders (
                        id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
                        public_number    bigint      NOT NULL UNIQUE DEFAULT nextval('order_public_number_seq'),
                        customer_id      uuid        NOT NULL REFERENCES customers (id),
                        venue_id         uuid        NOT NULL REFERENCES venues (id),
                        status           text        NOT NULL CHECK (status IN (
                                                                                'created', 'accepted', 'cooking', 'ready',
                                                                                'delivering', 'delivered', 'rejected', 'cancelled')),
                        total_minor      bigint      NOT NULL CHECK (total_minor >= 0),
                        currency         text        NOT NULL DEFAULT 'RUB',
                        delivery_address text        NOT NULL,
                        comment          text        NOT NULL DEFAULT '',
                        cancel_reason    text,
                        created_at       timestamptz NOT NULL DEFAULT now(),
                        updated_at       timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX orders_customer_idx     ON orders (customer_id, created_at DESC);
CREATE INDEX orders_venue_status_idx ON orders (venue_id, status, created_at DESC);

CREATE TRIGGER orders_set_updated_at
    BEFORE UPDATE ON orders
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Снапшот позиций на момент оформления.
CREATE TABLE order_items (
                             id                   uuid PRIMARY KEY DEFAULT gen_random_uuid(),
                             order_id             uuid    NOT NULL REFERENCES orders (id) ON DELETE CASCADE,
                             menu_item_id         uuid    REFERENCES menu_items (id) ON DELETE SET NULL,
                             name_snapshot        text    NOT NULL,
                             price_minor_snapshot bigint  NOT NULL CHECK (price_minor_snapshot >= 0),
                             quantity             integer NOT NULL CHECK (quantity > 0)
);

CREATE INDEX order_items_order_idx ON order_items (order_id);

CREATE TABLE order_status_history (
                                      id          bigserial PRIMARY KEY,
                                      order_id    uuid        NOT NULL REFERENCES orders (id) ON DELETE CASCADE,
                                      from_status text,
                                      to_status   text        NOT NULL,
                                      actor       text        NOT NULL CHECK (actor IN ('customer', 'venue', 'system')),
                                      comment     text        NOT NULL DEFAULT '',
                                      created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX order_status_history_order_idx ON order_status_history (order_id, created_at);

-- +goose Down
DROP TABLE IF EXISTS order_status_history;
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP SEQUENCE IF EXISTS order_public_number_seq;