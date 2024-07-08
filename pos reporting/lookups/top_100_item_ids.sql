--list of the top 100 item ids that have sold YTD 
create or replace view pos_reporting.top_100_item_ids as 
(
 SELECT r.tool_id::bigint AS item_id
 	,mcl.model
    ,sum(r.sales) AS total_sales
   FROM pos_reporting.retail_sales r
   left join clean_data.master_com_list mcl
   on r.tool_id::bigint = mcl.item_id
  WHERE r.sale_date >= '2024-01-01'::date
  GROUP BY (r.tool_id::bigint), mcl.model
  ORDER BY (sum(r.sales)) DESC
 LIMIT 100
 );
