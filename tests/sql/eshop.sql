-- https://chatgpt.com/share/68056914-1d00-8012-b762-deb5b7cf8cd4

/* PRODUCT CATEGORIES */
CREATE TABLE category
(
    id          SERIAL PRIMARY KEY,
    name        TEXT NOT NULL,
    description TEXT
);

/* PRODUCTS */
CREATE TABLE product
(
    id          SERIAL PRIMARY KEY,
    name        TEXT           NOT NULL,
    description TEXT,
    price       NUMERIC(10, 2) NOT NULL,
    sku         TEXT UNIQUE    NOT NULL,
    category_id INTEGER REFERENCES category (id),
    metadata    JSONB -- extensible product info (e.g. specs, variants)
);

/* CUSTOMERS */
CREATE TABLE customer
(
    id            SERIAL PRIMARY KEY,
    full_name     TEXT        NOT NULL,
    email         TEXT UNIQUE NOT NULL,
    phone         TEXT,
    bio           TEXT, -- long-form text about the customer (for RAG)
    registered_at TIMESTAMPTZ DEFAULT now()
);

/* ADDRESSES */
CREATE TABLE address
(
    id            SERIAL PRIMARY KEY,
    customer_id   INTEGER REFERENCES customer (id) ON DELETE CASCADE,
    address_line1 TEXT NOT NULL,
    address_line2 TEXT,
    city          TEXT NOT NULL,
    state         TEXT,
    postal_code   TEXT,
    country       TEXT NOT NULL,
    is_default    BOOLEAN DEFAULT FALSE
);

/* ORDERS */
CREATE TABLE "order"
(
    id                  SERIAL PRIMARY KEY,
    customer_id         INTEGER REFERENCES customer (id),
    shipping_address_id INTEGER REFERENCES address (id),
    status              TEXT NOT NULL DEFAULT 'pending',
    placed_at           TIMESTAMPTZ   DEFAULT now(),
    notes               TEXT -- extra text for RAG (e.g. delivery notes)
);

/* ORDER ITEMS */
CREATE TABLE order_item
(
    id          SERIAL PRIMARY KEY,
    order_id    INTEGER REFERENCES "order" (id) ON DELETE CASCADE,
    product_id  INTEGER REFERENCES product (id),
    quantity    INTEGER        NOT NULL CHECK (quantity > 0),
    unit_price  NUMERIC(10, 2) NOT NULL,
    total_price NUMERIC(10, 2) GENERATED ALWAYS AS (quantity * unit_price) STORED
);

/* PAYMENTS */
CREATE TABLE payment
(
    id                  SERIAL PRIMARY KEY,
    order_id            INTEGER        REFERENCES "order" (id) ON DELETE SET NULL,
    amount              NUMERIC(10, 2) NOT NULL,
    method              TEXT           NOT NULL, -- e.g. 'credit_card', 'paypal', 'crypto'
    paid_at             TIMESTAMPTZ DEFAULT now(),
    transaction_details TEXT                     -- long-form text from payment gateway
);

-- CATEGORIES
INSERT INTO category (name, description)
VALUES ('Books', 'Books spanning fiction, non-fiction, and educational material.'),
       ('Electronics', 'Gadgets and devices including phones, tablets, and accessories.'),
       ('Clothing', 'Apparel for men, women, and children, from casual to formal wear.');

-- PRODUCTS
INSERT INTO product (name, description, price, sku, category_id, metadata)
VALUES ('Wireless Earbuds',
        'High-fidelity Bluetooth earbuds with noise cancellation, long battery life, and a compact case. Ideal for workouts or commuting.',
        79.99, 'ELEC001', 2, '{
        "brand": "SoundMagic",
        "battery": "8h",
        "waterproof": true
    }'),

       ('Organic Cotton T-Shirt',
        'Eco-friendly t-shirt made from 100% organic cotton. Soft, breathable, and ethically produced.',
        24.50, 'CLO001', 3, '{
           "size": [
               "S",
               "M",
               "L",
               "XL"
           ],
           "colors": [
               "white",
               "black",
               "navy"
           ]
       }'),

       ('Science Fiction Novel: *The Red Orbit*',
        'A thrilling space odyssey following Commander Elara as she uncovers a galactic conspiracy across the moons of Jupiter.',
        15.00, 'BOOK001', 1, '{
           "author": "J. K. Nova",
           "pages": 384,
           "genre": "Sci-Fi"
       }');

-- CUSTOMERS
INSERT INTO customer (full_name, email, phone, bio)
VALUES ('Alice Montenegro', 'alice@example.com', '+1234567890',
        'Avid reader, coffee enthusiast, and amateur astronomer. Frequently shops for books and gadgets.'),

       ('Benji Howard', 'benji@example.com', '+1987654321',
        'Minimalist fashion lover and sustainability advocate. Prefers eco-friendly products and local brands.');

-- ADDRESSES
INSERT INTO address (customer_id, address_line1, city, state, postal_code, country, is_default)
VALUES (1, '123 Maple Street', 'Springfield', 'IL', '62704', 'USA', TRUE),
       (2, '456 Oak Avenue', 'Portland', 'OR', '97205', 'USA', TRUE);

-- ORDERS
INSERT INTO "order" (customer_id, shipping_address_id, status, notes)
VALUES (1, 1, 'shipped', 'Please leave the package behind the garden gate. Beware of the dog.'),
       (2, 2, 'processing', 'Gift wrap this item, and include a handwritten birthday note.');

-- ORDER ITEMS
INSERT INTO order_item (order_id, product_id, quantity, unit_price)
VALUES (1, 1, 1, 79.99), -- Wireless Earbuds
       (1, 3, 1, 15.00), -- Sci-fi Book
       (2, 2, 2, 24.50);
-- T-Shirts

-- PAYMENTS
INSERT INTO payment (order_id, amount, method, transaction_details)
VALUES (1, 94.99, 'credit_card', 'Paid with Visa **** 1234. Auth code: ZX8712. Issuer: CapitalOne.'),
       (2, 49.00, 'paypal', 'Transaction ID: PAYPAL-873456123. Buyer confirmed delivery preference.');
