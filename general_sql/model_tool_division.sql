create or replace view misc_views.model_tool_division as
(				
SELECT DISTINCT s1.model,s2.tool_id::integer, s1.division
FROM (--finds most recent model tool combo in ships
	--start s1
	 SELECT s1_1.model,
        	s1_1.tool_id,
        	s1_1.division,
        	max(s1_1.date_shipped) AS date_compare
     FROM ships_schema.ships s1_1
     WHERE 1=1
     and tool_id not like '%DORE%'
     and retailer in ('Walmart.com','Walmart Stores')
     and tool_id not like '%  %'
     and model !='7085335W'
     and( tool_id like '1%'
     or tool_id like '2%'
     or tool_id like '3%'
     or tool_id like '4%'
     or tool_id like '5%'
     or tool_id like '6%'
     or tool_id like '7%'
     or tool_id like '8%'
     or tool_id like '9%'
)
            
      GROUP BY s1_1.model, s1_1.tool_id, s1_1.division
    --end s1
      ) s1 
JOIN ( 
		SELECT DISTINCT ships.tool_id,
    					max(ships.date_shipped) AS date_compare
   		FROM ships_schema.ships
  		GROUP BY ships.tool_id) s2
ON s1.date_compare = s2.date_compare AND s1.tool_id::text = s2.tool_id::text
where 1=1
)
;

