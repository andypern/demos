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




#first, run drop_tables to make sure we don't have any stuff leftover

echo "cleaning up tables that may already exist"

/usr/bin/hive -e "drop table click;drop table users; drop table products; drop view clickview;"

##HBASE section##

#first, delete the hbase tables

echo "disable 'hbusers'; drop 'hbusers';" | hbase shell

# then, create a new hbase table



${DRILL_DEMODIR}/scripts/import_hbusers.sh





##HIVE tables

#first delete
/usr/bin/hive -e "drop table hive_clicks;drop table hive_users;"


# create the clicks table
/usr/bin/hive -f ${DRILL_DEMODIR}/scripts/create_hive_clicks.hql

# create a view tying 2 of these tables together.

/usr/bin/hive -f ${DEMODIR}/scripts/create_join_view.hql
#kickoff sharkserver2, but kill it if its running first

#only needed for now..

if [ -e /usr/bin/impala-shell ]
	then
	/usr/bin/impala-shell -q "invalidate metadata;" > /dev/null 2>&1
fi



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