#!/bin/bash

if [ -f ${DEMODIR}/scripts/env.sh ]
	then
	source ${DEMODIR}/scripts/env.sh
elif [ -f ./env.sh ]
	then
	source env.sh
else
	echo "env.sh not sourced, you need to chdir to /mapr/clustername/demos/spark-streaming-m7/scripts and run this from there."
	exit 1
fi



#if need be , blow away all tables + views

hive -e "drop table sensor;drop table pump_info; drop table maint_table;"


echo "now you need to run ${DEMODIR}/scripts/create_tables.sh"

