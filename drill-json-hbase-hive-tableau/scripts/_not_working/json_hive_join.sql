select h.user_cat, h.state, h.browser, h.lang, h.os, h.prod_cat, h.ad_id, h.purch_flag,
j.id, j.name, j.gender, j.address, j.first_visit
from  `hive`.`default`.`clicks` h
join dfs.`/drill/JSON/` j
on (h.id = j.id)
where h.purch_flag is not null