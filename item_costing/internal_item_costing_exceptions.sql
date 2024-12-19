create or replace view components.internal_item_costing_exceptions_view as 
(
 WITH t1 AS 
 ( -- first, find all of the previous months costs, container qty, and origin country
    SELECT model
    ,warehouse_number
    ,imp_status
    ,cost_date
    ,description
    ,origin_country
    ,container_qty
    ,material_cost
    ,duty_cost
    ,freight_cost
    ,lag(cost_date) OVER (PARTITION BY model, warehouse_number ORDER BY cost_date) AS prev_cost_date
    ,lag(origin_country) OVER (PARTITION BY model, warehouse_number ORDER BY cost_date) AS prev_origin_country
    ,lag(container_qty) OVER (PARTITION BY model, warehouse_number ORDER BY cost_date) AS prev_container_qty
    ,lag(material_cost) OVER (PARTITION BY model, warehouse_number ORDER BY cost_date) AS prev_material_cost
    ,lag(duty_cost) OVER (PARTITION BY model, warehouse_number ORDER BY cost_date) AS prev_duty_cost
    ,lag(freight_cost) OVER (PARTITION BY model, warehouse_number ORDER BY cost_date) AS prev_freight_cost
    ,row_number() OVER (ORDER BY model, warehouse_number, cost_date DESC) AS ic_id
    ,row_number() OVER (PARTITION BY model, warehouse_number ORDER BY cost_date DESC) AS model_warehouse_seq
    ,max(cost_date) OVER () AS latest_cost_date
    FROM item_costing.item_costing_tbl
)
, t2 AS 
( -- use case statements to mark a change in the new item costs vs old ones
SELECT 
    model
    ,warehouse_number
    ,imp_status
    ,cost_date
    ,description
    ,origin_country
    ,container_qty
    ,material_cost
    ,duty_cost
    ,freight_cost
    ,prev_cost_date
    ,prev_origin_country
    ,prev_container_qty
    ,prev_material_cost
    ,prev_duty_cost
    ,prev_freight_cost
    ,ic_id
    ,model_warehouse_seq
    ,latest_cost_date
    ,CASE
        WHEN origin_country <> prev_origin_country THEN 1
        ELSE 0
    END AS is_country_change
    ,CASE
        WHEN container_qty <> prev_container_qty THEN 1
        ELSE 0
    END AS is_container_qty_change
    ,CASE
        WHEN material_cost <> prev_material_cost THEN 1
        ELSE 0
    END AS is_material_cost_change
    ,CASE
        WHEN duty_cost <> prev_duty_cost THEN 1
        ELSE 0
    END AS is_duty_cost_change
    ,CASE
        WHEN freight_cost <> prev_freight_cost THEN 1
        ELSE 0
    END AS is_freight_cost_change
    ,CASE
        WHEN cost_date <> latest_cost_date THEN 1
        ELSE 0
    END AS is_not_on_new_cost_update
FROM t1
WHERE 1 = 1 AND model_warehouse_seq = 1
ORDER BY ic_id
        )
 SELECT 
    model
    ,warehouse_number
    ,imp_status
    ,cost_date
    ,description
    ,origin_country
    ,container_qty
    ,material_cost
    ,duty_cost
    ,freight_cost
    ,prev_origin_country
    ,prev_container_qty
    ,prev_material_cost
    ,prev_duty_cost
    ,prev_freight_cost
    ,CASE -- based off changes, create a description for the scenarios
        WHEN is_not_on_new_cost_update = 1 THEN 'This Item is not featured in the latest Costing Sheet'::text
        WHEN (is_container_qty_change + is_material_cost_change + is_duty_cost_change + is_freight_cost_change) >= 1 THEN 'This Item has at least one cost change or container change'::text
        WHEN (is_container_qty_change + is_material_cost_change + is_duty_cost_change + is_freight_cost_change) = 0 THEN 'This Item doesn''t have any cost or container changes'::text
        ELSE NULL::text
    END AS change_description
    ,is_country_change
   FROM t2
  ORDER BY model, warehouse_number
  );