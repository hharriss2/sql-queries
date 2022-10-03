--find account manager like search bar

select account_manager as "Account Manager", c.category_name as "Category"
from account_manager a
left join category c ON a.account_manager_id = c.am_id
where lower(account_manager) IN (SELECT LOWER(account_manager) 
                                                      from account_manager 
                                                      where lower(account_manager) LIKE  {{'%' + textInput1.value + '%'}} )