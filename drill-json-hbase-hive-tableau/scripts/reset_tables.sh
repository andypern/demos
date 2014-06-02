#!/bin/bash

if [ -f ${DRILL_DEMODIR}/scripts/env.sh ]
	then
	source ${DRILL_DEMODIR}/scripts/env.sh
elif [ -f ./env.sh ]
	then
	source env.sh
else
	echo "env.sh not sourced, you need to chdir to /mapr/clustername/demos/drill-json-hbase-hive-tableau/scripts and run this from there."
	exit 1
fi





##HBASE section##

#first, delete the hbase tables

echo "disable 'hbusers'; drop 'hbusers';" | hbase shell

# then, create a new hbase table



${DRILL_DEMODIR}/scripts/import_hbusers.sh





##HIVE tables

#first delete
/usr/bin/hive -e "drop table clicks;drop table users;"


# create the clicks table
/usr/bin/hive -f ${DRILL_DEMODIR}/scripts/create_hive_clicks.hql

#create the hive users table:
/usr/bin/hive -f ${DRILL_DEMODIR}/scripts/create_hive_users.hql

##start/restart drill

clush -a "/opt/mapr/drill/drill-1.0.0/apache-drill-1.0.0-m2-incubating-SNAPSHOT/bin/drillbit.sh restart"

echo "sleeping for 30 seconds to let drillbit startup"

# run information schema qry

${SQLLINE} --run=${DRILL_DEMODIR}/scripts/info_schema.sql


