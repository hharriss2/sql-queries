select wk_3.tool_id-- take the latest tool id 
,wk_3.review_rating as wk_3_review_rating
, wk_3.review_count as wk_3_review_count
,wk_3.date_inserted as wk_3_date_inserted
,wk_2.review_rating as wk_2_review_rating
,wk_2.review_count as wk_2_review_count
,wk_2.date_inserted as wk_2_date_inserted
,wk_1.review_rating as wk_1_review_rating
,wk_1.review_count as wk_1_review_count
,wk_1.date_inserted as wk_1_date_inserted
from
	(
		select distinct rr.tool_id, review_rating, review_count, date_inserted
		from scrape_data.scrape_history sh-- need all scrape data to get last 3 weeks worth
		join pd_tasks.rating_and_reviews rr-- rating and reviews are what items PD needs for their sheet
		on sh.item_id = rr.tool_id::integer -- if this ever slows down, could remake r&r lookup with tool id being a integer
		where btrim(to_char(sh.date_inserted,'Day'),' ') = 'Friday'--turns a date into the date name
		and date_inserted >current_date - interval '7 Days'/*find a the most current week of raitngs and reviews. Might need to change to do the most current friday since the upload will happen on fridays. 
		This means move the meet */
	) wk_3 -- 1 week prior
LEFT JOIN
	(
		select distinct rr.tool_id, review_rating, review_count, date_inserted
		from scrape_data.scrape_history sh
		join pd_tasks.rating_and_reviews rr
		on sh.item_id = rr.tool_id::integer
		where btrim(to_char(sh.date_inserted,'Day'),' ') = 'Friday'
		and date_inserted >current_date - interval '14 Days'
		and date_inserted <current_date - interval '7 Days'
	)wk_2 -- 2 weeks prior
ON wk_3.tool_id = wk_2.tool_id
LEFT JOIN
	(
		select distinct rr.tool_id, review_rating, review_count, date_inserted
		from scrape_data.scrape_history sh
		join pd_tasks.rating_and_reviews rr
		on sh.item_id = rr.tool_id::integer
		where btrim(to_char(sh.date_inserted,'Day'),' ') = 'Friday'
		and date_inserted >current_date - interval '21 Days'
		and date_inserted <current_date - interval '14 Days'
	)wk_1 -- 3 weeks prior
ON wk_1.tool_id = wk_2.tool_id

;
