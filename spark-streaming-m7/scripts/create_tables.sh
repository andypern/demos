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




#first, run drop_tables to make sure we don't have any stuff leftover

echo "cleaning up tables that may already exist"
sh ./drop_tables.sh

#first, create the table pointing to M7, but first blow it away and re-create a dummy one.

if [ -L /mapr/${CLUSTER}/${TABLENAME} ]
	then
		echo "deleting existing table /mapr/${CLUSTER}/${TABLENAME}"
		rm -f  /mapr/${CLUSTER}/${TABLENAME}
fi

mkdir -p /mapr/${CLUSTER}/tables
maprcli table create -path ${TABLENAME}
maprcli table cf create -path ${TABLENAME} -cfname cf1

/usr/bin/hive -f create_ext_table.hql

#next, create the table used for pump_vendor info:

/usr/bin/hive -f create_pump_table.hql

# create the maintenance table
/usr/bin/hive -f create_maint_table.hql

# create a view tying 2 of these tables together.

#kickoff sharkserver2, but kill it if its running first

if ps auxw|grep SharkServer2|grep -v grep|awk {'print $2'}
	then
	OLD_SHARK_PID=`ps auxw|grep SharkServer2|grep -v grep|awk {'print $2'}`
	kill -9 ${OLD_SHARK_PID}
fi

${SHARK_BIN} --service sharkserver2 &
SS2_PID=$!
echo ${SS2_PID} > ${BASEDIR}/sharkserver2.pid
disown

#wait 15 seconds to let sharkserver2 get running
sleep 15

#verify we can see tables via JDBC+sharkserver2

echo "showing tables via beeline/jdbc + sharkserver2"

${SHARK_BIN} --service beeline -u jdbc:hive2://${MYHOST}:10000 -n mapr -p mapr -d org.apache.hive.jdbc.HiveDriver -e "show tables;"

echo "if you saw 3 or more tables..all is well."

exit 0