--used for the order type in purchase orders
CREATE TABLE walmart.dim_sources.dim_order_type (
    order_type_id INTEGER IDENTITY(1,1),
    order_type_name STRING,
    inserted_at TIMESTAMP,
    PRIMARY KEY (id)
);
