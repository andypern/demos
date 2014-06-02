select c.user_cat, c.state, c.ad_id, c.prod_cat, u.name, 
u.gender, u.address
from `hive`.`default`.`clicks` c
join `hive`.`default`.`users` u
on c.id = u.id
where c.purch_flag = '"true"'
limit 10;