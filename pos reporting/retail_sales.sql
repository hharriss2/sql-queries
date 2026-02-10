 SELECT id,
    item_id::text AS tool_id,
    product_name,
    upc,
    brand_name,
    base_upc,
    sale_date,
    wm_week + 100 AS wm_week,
    units,
    sales,
    item_type,
    is_put,
        CASE
            WHEN dsv_order_id IS NOT NULL THEN 3
            when vendor_nbr = '120351'
            then 4 
            ELSE 2
        END AS retail_type_id
   FROM retail_link_pos;