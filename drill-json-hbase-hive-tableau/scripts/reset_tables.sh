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







##HIVE tables

#first delete
/usr/bin/hive -e "drop table clicks;drop table users;"


#put datasets into place

mkdir -p ${DRILL_BASEDIR}
cp -R ${DRILL_DEMODIR}/data/* ${DRILL_BASEDIR}
chmod -R 777 ${DRILL_BASEDIR}


# create the clicks table
/usr/bin/hive -f ${DRILL_DEMODIR}/scripts/create_hive_clicks.hql

#create the hive users table:
/usr/bin/hive -f ${DRILL_DEMODIR}/scripts/create_hive_users.hql


##HBASE section##

#first, delete the hbase tables

echo "disable 'hbusers'; drop 'hbusers';" | hbase shell

# then, create a new hbase table



sh ${DRILL_DEMODIR}/scripts/import_hbusers.sh





##start/restart drill

clush -a "/opt/mapr/drill/drill-1.0.0/apache-drill-1.0.0-m2-incubating-SNAPSHOT/bin/drillbit.sh restart"

echo "sleeping for 30 seconds to let drillbit startup"
sleep 30;
# run information schema qry

${SQLLINE} --run=${DRILL_DEMODIR}/scripts/info_schema.sql


