#!/bin/bash

. ./env.sh

#first, create the table pointing to M7
/usr/bin/hive -f create_ext_table.hql

#next, create the table used for pump_vendor info:

/usr/bin/hive -f create_pump_table.hql

# create the maintenance table
/usr/bin/hive -f create_maint_table.hql

