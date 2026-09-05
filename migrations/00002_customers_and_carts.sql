-- +goose Up
CREATE TABLE customers (
                           id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
                           created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE carts (
                       id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
                       customer_id uuid        NOT NULL REFERENCES customers (id) ON DELETE CASCADE,
                       venue_id    uuid        REFERENCES venues (id) ON DELETE CASCADE,
                       status      text        NOT NULL DEFAULT 'active'
                           CHECK (status IN ('active', 'ordered', 'abandoned')),
                       created_at  timestamptz NOT NULL DEFAULT now(),
                       updated_at  timestamptz NOT NULL DEFAULT now()
);

-- У покупателя может быть максимум одна активная корзина.
CREATE UNIQUE INDEX carts_one_active_per_customer_idx
    ON carts (customer_id) WHERE status = 'active';

CREATE TRIGGER carts_set_updated_at
    BEFORE UPDATE ON carts
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE cart_items (
                            id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
                            cart_id      uuid        NOT NULL REFERENCES carts (id) ON DELETE CASCADE,
                            menu_item_id uuid        NOT NULL REFERENCES menu_items (id) ON DELETE CASCADE,
                            quantity     integer     NOT NULL CHECK (quantity > 0 AND quantity <= 100),
                            created_at   timestamptz NOT NULL DEFAULT now(),
                            updated_at   timestamptz NOT NULL DEFAULT now(),
                            UNIQUE (cart_id, menu_item_id)
);

CREATE TRIGGER cart_items_set_updated_at
    BEFORE UPDATE ON cart_items
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- +goose Down
DROP TABLE IF EXISTS cart_items;
DROP TABLE IF EXISTS carts;
DROP TABLE IF EXISTS customers;