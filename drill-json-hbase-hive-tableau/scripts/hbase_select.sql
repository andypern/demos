select cast(account['id'] as VarChar(20)) as id,
cast(account['name'] as VarChar(20)) as name,
cast(metrics['gender'] as VarChar(20)) as gender,
cast(address['address'] as VarChar(20)) as address,
cast(metrics['first_visit'] as VarChar(20)) as first_visit from hbase.`hbusers` limit 10;