#!/bin/bash

. ./env.sh

#first, create the table pointing to M7, but first we have to make a dummy m7 table and remove it

maprcli table create -path ${TABLENAME}
maprcli table cf create -path ${TABLENAME} -cfname cf1

/usr/bin/hive -f create_ext_table.hql

#next, create the table used for pump_vendor info:

/usr/bin/hive -f create_pump_table.hql

# create the maintenance table
/usr/bin/hive -f create_maint_table.hql

# create a view tying all these tables together.


hive -e "show tables;"