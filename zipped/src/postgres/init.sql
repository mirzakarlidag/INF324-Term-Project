-- Active: 1741906622540@@127.0.0.1@33067
CREATE TABLE IF NOT EXISTS UNIT (
    unit_id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    symbol VARCHAR(10) NOT NULL
);

CREATE TABLE IF NOT EXISTS PRODUCT_TYPE (
    product_type_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS COMPONENT_GROUP (
    group_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS COMPONENT_CATEGORY (
    category_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    group_id INTEGER NOT NULL,
    CONSTRAINT fk_category_group FOREIGN KEY (group_id)
        REFERENCES COMPONENT_GROUP(group_id) ON DELETE RESTRICT,
    UNIQUE(name, group_id)
);

CREATE TABLE IF NOT EXISTS COMPONENT_SUBCATEGORY (
    sub_category_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    category_id INTEGER NOT NULL,
    CONSTRAINT fk_subcategory_category FOREIGN KEY (category_id)
        REFERENCES COMPONENT_CATEGORY(category_id) ON DELETE RESTRICT,
    UNIQUE(name, category_id)
);

CREATE TABLE IF NOT EXISTS MARKET (
    market_id SERIAL PRIMARY KEY,
    country VARCHAR(100) NOT NULL,
    region VARCHAR(100) NOT NULL,
    UNIQUE(country, region)
);

CREATE TABLE IF NOT EXISTS PLUG_TYPE (
    plug_type_id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS ENERGY_CLASS (
    energy_class_id SERIAL PRIMARY KEY,
    name VARCHAR(10) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS PRODUCT (
    sku CHAR(10) PRIMARY KEY,
    model VARCHAR(100) NOT NULL,
    product_type_id INTEGER NOT NULL,
    volume DECIMAL(10,2),
    color VARCHAR(50),
    CONSTRAINT fk_product_type FOREIGN KEY (product_type_id)
        REFERENCES PRODUCT_TYPE(product_type_id) ON DELETE RESTRICT,
    CONSTRAINT sku_format CHECK (sku ~ '^[0-9]{10}$'),
    CONSTRAINT product_volume_positive CHECK (volume > 0)
);

CREATE TABLE IF NOT EXISTS PRODUCT_MARKET (
    sku CHAR(10),
    market_id INTEGER,
    plug_type_id INTEGER NOT NULL,
    energy_class_id INTEGER NOT NULL,
    PRIMARY KEY (sku, market_id),
    CONSTRAINT fk_product_market_sku FOREIGN KEY (sku)
        REFERENCES PRODUCT(sku) ON DELETE CASCADE,
    CONSTRAINT fk_product_market_market FOREIGN KEY (market_id)
        REFERENCES MARKET(market_id) ON DELETE RESTRICT,
    CONSTRAINT fk_product_market_plug FOREIGN KEY (plug_type_id)
        REFERENCES PLUG_TYPE(plug_type_id) ON DELETE RESTRICT,
    CONSTRAINT fk_product_market_energy FOREIGN KEY (energy_class_id)
        REFERENCES ENERGY_CLASS(energy_class_id) ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS COMPONENT (
    stock_number CHAR(10) PRIMARY KEY,
    description TEXT NOT NULL,
    unit_id INTEGER NOT NULL,
    sub_category_id INTEGER NOT NULL,
    CONSTRAINT fk_component_unit FOREIGN KEY (unit_id)
        REFERENCES UNIT(unit_id) ON DELETE RESTRICT,
    CONSTRAINT fk_component_subcategory FOREIGN KEY (sub_category_id)
        REFERENCES COMPONENT_SUBCATEGORY(sub_category_id) ON DELETE RESTRICT,
    CONSTRAINT stock_number_format CHECK (stock_number ~ '^[0-9]{10}$')
);

CREATE TABLE IF NOT EXISTS COMPONENT_RELATION (
    parent_stock_number CHAR(10),
    child_stock_number CHAR(10),
    quantity DECIMAL(10,3) NOT NULL,
    unit_id INTEGER NOT NULL,
    PRIMARY KEY (parent_stock_number, child_stock_number),
    CONSTRAINT fk_component_relation_parent FOREIGN KEY (parent_stock_number)
        REFERENCES COMPONENT(stock_number) ON DELETE RESTRICT,
    CONSTRAINT fk_component_relation_child FOREIGN KEY (child_stock_number)
        REFERENCES COMPONENT(stock_number) ON DELETE RESTRICT,
    CONSTRAINT fk_component_relation_unit FOREIGN KEY (unit_id)
        REFERENCES UNIT(unit_id) ON DELETE RESTRICT,
    CONSTRAINT quantity_positive CHECK (quantity > 0),
    CONSTRAINT no_self_reference CHECK (parent_stock_number != child_stock_number)
);

CREATE TABLE IF NOT EXISTS PRODUCT_COMPONENT (
    sku CHAR(10),
    stock_number CHAR(10),
    quantity DECIMAL(10,3) NOT NULL,
    unit_id INTEGER NOT NULL,
    PRIMARY KEY (sku, stock_number),
    CONSTRAINT fk_product_component_sku FOREIGN KEY (sku)
        REFERENCES PRODUCT(sku) ON DELETE CASCADE,
    CONSTRAINT fk_product_component_stock FOREIGN KEY (stock_number)
        REFERENCES COMPONENT(stock_number) ON DELETE RESTRICT,
    CONSTRAINT fk_product_component_unit FOREIGN KEY (unit_id)
        REFERENCES UNIT(unit_id) ON DELETE RESTRICT,
    CONSTRAINT pc_quantity_positive CHECK (quantity > 0)
);

CREATE TABLE IF NOT EXISTS PRODUCTION_LINE (
    prod_line_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    capacity_per_day INTEGER NOT NULL,
    CONSTRAINT capacity_positive CHECK (capacity_per_day > 0)
);

CREATE TABLE IF NOT EXISTS PRODUCTION_LINE_PRODUCT (
    prod_line_id INTEGER,
    sku CHAR(10),
    PRIMARY KEY (prod_line_id, sku),
    CONSTRAINT fk_prod_line_product_line FOREIGN KEY (prod_line_id)
        REFERENCES PRODUCTION_LINE(prod_line_id) ON DELETE CASCADE,
    CONSTRAINT fk_prod_line_product_sku FOREIGN KEY (sku)
        REFERENCES PRODUCT(sku) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS CUSTOMER (
    customer_id SERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    market_id INTEGER NOT NULL,
    CONSTRAINT fk_customer_market FOREIGN KEY (market_id)
        REFERENCES MARKET(market_id) ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS "ORDER" (
    order_id SERIAL PRIMARY KEY,
    customer_id INTEGER NOT NULL,
    order_date DATE NOT NULL DEFAULT CURRENT_DATE,
    status VARCHAR(50) NOT NULL,
    CONSTRAINT fk_order_customer FOREIGN KEY (customer_id)
        REFERENCES CUSTOMER(customer_id) ON DELETE RESTRICT,
    CONSTRAINT order_status_valid CHECK (status IN ('NEW', 'APPROVED', 'SHIPPED', 'CANCELLED')),
    CONSTRAINT order_date_not_future CHECK (order_date <= CURRENT_DATE)
);

CREATE TABLE IF NOT EXISTS ORDER_PRODUCT (
    order_id INTEGER,
    sku CHAR(10),
    quantity INTEGER NOT NULL,
    PRIMARY KEY (order_id, sku),
    CONSTRAINT fk_order_product_order FOREIGN KEY (order_id)
        REFERENCES "ORDER"(order_id) ON DELETE CASCADE,
    CONSTRAINT fk_order_product_sku FOREIGN KEY (sku)
        REFERENCES PRODUCT(sku) ON DELETE RESTRICT,
    CONSTRAINT op_quantity_positive CHECK (quantity > 0)
);

CREATE TABLE IF NOT EXISTS TRANSPORTATION_TYPE (
    transportation_type_id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    capacity INTEGER NOT NULL,
    CONSTRAINT transportation_capacity_positive CHECK (capacity > 0)
);

CREATE TABLE IF NOT EXISTS TRANSPORTATION (
    transportation_id SERIAL PRIMARY KEY,
    transportation_type_id INTEGER NOT NULL,
    destination_market_id INTEGER NOT NULL,
    order_id INTEGER NOT NULL,
    planned_date DATE NOT NULL,
    status VARCHAR(50) NOT NULL,
    CONSTRAINT fk_transportation_type FOREIGN KEY (transportation_type_id)
        REFERENCES TRANSPORTATION_TYPE(transportation_type_id) ON DELETE RESTRICT,
    CONSTRAINT fk_transportation_market FOREIGN KEY (destination_market_id)
        REFERENCES MARKET(market_id) ON DELETE RESTRICT,
    CONSTRAINT fk_transportation_order FOREIGN KEY (order_id)
        REFERENCES "ORDER"(order_id) ON DELETE CASCADE,
    CONSTRAINT transportation_status_valid CHECK (status IN ('NEW', 'APPROVED', 'SHIPPED', 'CANCELLED')),
    CONSTRAINT planned_date_not_past CHECK (planned_date >= CURRENT_DATE)
);

CREATE INDEX IF NOT EXISTS idx_component_relation_parent ON COMPONENT_RELATION(parent_stock_number);
CREATE INDEX IF NOT EXISTS idx_component_relation_child ON COMPONENT_RELATION(child_stock_number);

CREATE INDEX IF NOT EXISTS idx_product_type ON PRODUCT(product_type_id);
CREATE INDEX IF NOT EXISTS idx_product_model ON PRODUCT(model);

CREATE INDEX IF NOT EXISTS idx_component_subcategory ON COMPONENT(sub_category_id);
CREATE INDEX IF NOT EXISTS idx_component_category ON COMPONENT_SUBCATEGORY(category_id);
CREATE INDEX IF NOT EXISTS idx_component_group ON COMPONENT_CATEGORY(group_id);

CREATE INDEX IF NOT EXISTS idx_order_customer ON "ORDER"(customer_id);
CREATE INDEX IF NOT EXISTS idx_order_date ON "ORDER"(order_date);
CREATE INDEX IF NOT EXISTS idx_order_status ON "ORDER"(status);

CREATE INDEX IF NOT EXISTS idx_transportation_type ON TRANSPORTATION(transportation_type_id);
CREATE INDEX IF NOT EXISTS idx_transportation_market ON TRANSPORTATION(destination_market_id);
CREATE INDEX IF NOT EXISTS idx_transportation_order ON TRANSPORTATION(order_id);
CREATE INDEX IF NOT EXISTS idx_transportation_date ON TRANSPORTATION(planned_date);
CREATE INDEX IF NOT EXISTS idx_transportation_status ON TRANSPORTATION(status);

CREATE INDEX IF NOT EXISTS idx_customer_market ON CUSTOMER(market_id);
