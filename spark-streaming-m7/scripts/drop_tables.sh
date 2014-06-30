#!/bin/bash

if [ -f ${LABDIR}/scripts/env.sh ]
	then
	source ${LABDIR}/scripts/env.sh
elif [ -f ./env.sh ]
	then
	source ./env.sh
else
	echo "env.sh not sourced, you need to chdir to /mapr/clustername/user/username/spark/scripts and run this from there."
	exit 1
fi



#if need be , blow away all tables + views

hive -e "drop table ${USERNAME}_SPARK_sensor;drop table ${USERNAME}_SPARK_pump_info; drop table ${USERNAME}_SPARK_maint_table;"


echo "to re-create tables, run ${LABDIR}/scripts/create_tables.sh"

