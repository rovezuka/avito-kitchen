-- +goose Up

-- Триграммный индекс для поиска блюд по подстроке (ILIKE '%шаур%').
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Общая функция автообновления updated_at.
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION set_updated_at() RETURNS trigger AS $$
BEGIN
    NEW.updated_at = now();
RETURN NEW;
END;
$$ LANGUAGE plpgsql;
-- +goose StatementEnd

CREATE TABLE venues (
                        id                     uuid PRIMARY KEY DEFAULT gen_random_uuid(),
                        slug                   text        NOT NULL UNIQUE,
                        name                   text        NOT NULL,
                        description            text        NOT NULL DEFAULT '',
                        address                text        NOT NULL,
                        cuisine                text        NOT NULL DEFAULT '',
                        is_active              boolean     NOT NULL DEFAULT true,
                        min_order_amount_minor bigint      NOT NULL DEFAULT 0 CHECK (min_order_amount_minor >= 0),
                        opens_at               time        NOT NULL DEFAULT '00:00',
                        closes_at              time        NOT NULL DEFAULT '23:59',
                        webhook_url            text,
                        api_key_hash           text        NOT NULL UNIQUE,
                        created_at             timestamptz NOT NULL DEFAULT now(),
                        updated_at             timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX venues_active_idx ON venues (is_active) WHERE is_active;

CREATE TRIGGER venues_set_updated_at
    BEFORE UPDATE ON venues
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE menu_categories (
                                 id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
                                 venue_id    uuid        NOT NULL REFERENCES venues (id) ON DELETE CASCADE,
                                 external_id text        NOT NULL,
                                 name        text        NOT NULL,
                                 sort_order  integer     NOT NULL DEFAULT 0,
                                 created_at  timestamptz NOT NULL DEFAULT now(),
                                 updated_at  timestamptz NOT NULL DEFAULT now(),
                                 UNIQUE (venue_id, external_id)
);

CREATE TRIGGER menu_categories_set_updated_at
    BEFORE UPDATE ON menu_categories
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE menu_items (
                            id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
                            venue_id     uuid        NOT NULL REFERENCES venues (id) ON DELETE CASCADE,
                            category_id  uuid        REFERENCES menu_categories (id) ON DELETE SET NULL,
                            external_id  text        NOT NULL,
                            name         text        NOT NULL,
                            description  text        NOT NULL DEFAULT '',
                            price_minor  bigint      NOT NULL CHECK (price_minor > 0),
                            currency     text        NOT NULL DEFAULT 'RUB',
                            is_available boolean     NOT NULL DEFAULT true,
                            deleted_at   timestamptz,
                            created_at   timestamptz NOT NULL DEFAULT now(),
                            updated_at   timestamptz NOT NULL DEFAULT now(),
                            UNIQUE (venue_id, external_id)
);

CREATE INDEX menu_items_venue_idx  ON menu_items (venue_id) WHERE deleted_at IS NULL;
CREATE INDEX menu_items_name_trgm_idx ON menu_items USING gin (name gin_trgm_ops);

CREATE TRIGGER menu_items_set_updated_at
    BEFORE UPDATE ON menu_items
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- +goose Down
DROP TABLE IF EXISTS menu_items;
DROP TABLE IF EXISTS menu_categories;
DROP TABLE IF EXISTS venues;
DROP FUNCTION IF EXISTS set_updated_at();