#!/bin/sh

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



TABLE="hbusers"
FILE=${DRILL_BASEDIR}/CSV/user1.csv
CF1="account"
CF2="address"
CF3="metrics"


export HBASE_HOME=/opt/mapr/hbase/hbase-0.94.17/
JAR=$HBASE_HOME/hbase-0.94.17-mapr-1403-SNAPSHOT.jar


echo "create '${TABLE}','${CF1}','${CF2}','${CF3}'" | hbase shell



# run m/r import job
hadoop jar $JAR importtsv \
    -Dimporttsv.separator=, \
    -Dimporttsv.columns=HBASE_ROW_KEY,${CF1}:id,$CF1:name,$CF3:metrics,$CF2:address,$CF3:first_visit \
    $TABLE \
    $FILE
