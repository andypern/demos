#!/bin/bash

. ./env.sh

#first, create the table pointing to M7, but first blow it away and re-create a dummy one.

if [ -L /mapr/${CLUSTER}/${TABLENAME} ]
	then
		echo "deleting existing table /mapr/${CLUSTER}/${TABLENAME}"
		rm -f  /mapr/${CLUSTER}/${TABLENAME}
fi

maprcli table create -path ${TABLENAME}
maprcli table cf create -path ${TABLENAME} -cfname cf1

/usr/bin/hive -f create_ext_table.hql

#next, create the table used for pump_vendor info:

/usr/bin/hive -f create_pump_table.hql

# create the maintenance table
/usr/bin/hive -f create_maint_table.hql

# create a view tying all these tables together.
#kickoff sharkserver2, but kill it if its running first

${SHARK_BIN} --service sharkserver2 &
SS2_PID=$!
echo ${SS2_PID} > ${BASEDIR}/sharkserver2.pid
disown

#verify we can see tables via shark shell

echo "showing tables via shark shell"
${SHARK_BIN} -e "show tables;"

#verify we can see tables via JDBC+sharkserver2

echo "showing tables via beeline/jdbc + sharkserver2"

${SHARK_BIN} --service beeline -u jdbc:hive2://${MYHOST}:10000 -n mapr -p mapr -d org.apache.hive.jdbc.HiveDriver -e "show tables;"

echo "if you saw 3 or more tables..all is well."

exit 0