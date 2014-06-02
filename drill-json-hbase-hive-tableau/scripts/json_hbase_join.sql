  select hb.name, hv.state from
  ( select cast(account['id'] as VarChar(20)) as id, cast(account['name'] as VarChar(20)) as name FROM hbase.`hbusers`)hb
join 