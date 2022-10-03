--Some query I worked on for retool. input boxes at the bottom 
  select distinct pf.model::text
        ,case when pr.division = 'Dorel Home Products' then 'DHP'
        when pr.division = 'Dorel Asia' then 'Dorel Living' else 
        pr.division end as division
        , cbm.cat
        , pf.tool_id::text
        ,pr.product_name
        , pf.sum_units promo_units
        , pf.sum_sales as promo_sales
        , funding_amt
        , funding_total::FLOAT
        ,pf.count_week as promo_week_count
        , count_weeks.count_week LY_week_count
        ,sum_units.sum_units as LY_units
        , (sum_units.sum_units/count_weeks.count_week) * pf.count_week as expected_units
        , sum_units.sum_sales LY_sales
        ,(sum_units.sum_sales/sum_units.sum_units)* (((sum_units.sum_units/count_weeks.count_week) * pf.count_week))::FLOAT as expected_sales
        ,pf.sum_sales - ((sum_units.sum_sales/sum_units.sum_units)* ((sum_units.sum_units/count_weeks.count_week) * pf.count_week)) as incramental_gain
        ,((pf.sum_sales - ((sum_units.sum_sales/sum_units.sum_units)* ((sum_units.sum_units/count_weeks.count_week) * pf.count_week)))-funding_total)/funding_total as ROI
from 
  (--wrapping querie to find the count of weeks
  select model
    ,tool_id
    ,count(distinct wm_week) count_week
    ,sum(sum_units) sum_units
    ,funding_amt
    ,sum(funding_total) as funding_total
    ,sum(sum_sales) as sum_sales
  from
  ( -- sum of sales for item during promo 
    select model
      ,tool_id
      ,wm_week
      , sum(units) sum_units
      , funding_amt
      , sum(sales_funding) funding_total
      , sum(sales) as sum_sales
    from
      (
        select * 
        from pos_reporting.promo_funding_sales
        where 1=1 
        and promo_type = 'Tax Time 2022'-- only need tax time promo
      ) pf
--      where tool_id = '15063498'
    group by model, tool_id,wm_week, funding_amt
    having sum(units) >0 -- omiting any promos that did less than 0 as a whole
    ) pf
    group by model, tool_id, funding_amt
      )pf
left join 
  (-- sum of sales for 2021 by item
  select * 
  from
    (
    select tool_id
      ,sum(sum_units) as sum_units
      , sum(sum_sales) as sum_sales
    from (  --sub query to get aur 
     select tool_id
       ,wm_week
       ,promo_aur
       ,case when sum_units != 0 
         then
           case when sum_sales/sum_units > promo_aur 
             then sum_units * (1+ l13_2021_over_2020)
             else sum_units
             end 
         else 0 
         end as sum_units
       ,case when sum_units !=0
         then
           case when sum_sales/sum_units > promo_aur
             then sum_sales * (1+l13_2021_over_2020)
             else sum_sales
             end
         else 0 
         end as sum_sales
     from
        (
          --get item id, week, and sum of sales and units for that week
          select distinct 
              r.tool_id
            , wm_week
            ,coalesce(d.l13_2021_over_2020,0) as l13_2021_over_2020
            ,coalesce(d.promo_aur,0) as promo_aur
            , sum(units) as sum_units
            , sum(sales) as sum_sales
            --,sum(sales)/sum(units) as aur_2021
            --apply deviance from promo aur here
          from pos_reporting.retail_sales r
          left join pos_reporting.aur_deviance d
          on r.tool_id::integer = d.tool_id
          where r.tool_id::integer in 
                  (/*Certian promo items. 
                  Ran select distinct tool id from promo type*/
                  select tool_id::integer 
                  from temp_tool_ids
                  )
          and wm_week >=202201 and wm_week <=202252
          group by r.tool_id
            , wm_week
            ,d.l13_2021_over_2020
            ,d.promo_aur
          ) sales_by_week_2021
        ) t1
      where sum_units >0 
      --have to omit 0 units after they've been summed 
      group by tool_id
      
  
    ) sum_units
  ) sum_units
on sum_units.tool_id::integer = pf.tool_id
left join 
  (
  select * 
  from  
   ( -- same logic as getting 2021 sales. However this time we want to get a week count
  select tool_id, count(distinct wm_week) as count_week
  from
    (
    select distinct tool_id, wm_week, sum(units) as sum_units 
    from pos_reporting.retail_sales
    where tool_id::integer in (select tool_id::integer from temp_tool_ids)
    and wm_week >=202201 and wm_week <=202252
    group by tool_id, wm_week
    ) t1
   where  sum_units >0
   group by tool_id
   )count_weeks
  )count_weeks
on pf.tool_id = count_weeks.tool_id::integer
left join products_raw pr 
on pr.model = pf.model 
left join cat_by_model cbm 
on cbm.model = pf.model 
where 1=1
and ({{txtIn_category.value.length===0 }} 
  OR cbm.cat = ANY({{ txtIn_category.value }}))

and ( {{txtIn_model.value.length===0 }} 
  OR pf.model = ANY({{ txtIn_model.value }}))
order by promo_units
--filters are important piece here. work with no or selected values
;  
