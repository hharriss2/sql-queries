--view used for power bi reports
create or replace view power_bi.wm_calendar_view as
(
SELECT
    id AS wmcal_id
    ,date
    ,wm_week
    ,wm_year
    ,wm_date
    ,COALESCE(wm_sale_month,
        CASE
            WHEN wm_week = '1'::text THEN 'February'::text
            ELSE btrim(to_char(date::timestamp with time zone, 'Month'::text))
        END) AS month
    ,wm_quarter
    ,case -- find the days leading up to the current date. for multiple year
		when date_part('month',date) = date_part('month',current_date)
		and date_part('day',date) <= date_part('day',current_date)
		then 1 else 0 
		end as is_mtd_ey -- month to date every year
	,case-- find months+days leading up to current date. for every year
		when date_part('month',date) <= date_part('month',current_date)
		and date_part('day',date) <= date_part('day',current_date)
		then 1
		when date_part('month',date) <= date_part('month',current_date)
		then 1 
		else 0 
		end as is_ytd_ey --year to date every year
FROM wm_calendar
)
   ;