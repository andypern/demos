#!/usr/bin/bash

#first stop the shark service via maprcli

SPARK_MASTER_HOST=`maprcli node list -columns hostname,svc|grep spark|awk {'print $2'}`
echo "stopping spark-master service on ${SPARK_MASTER_HOST}"
maprcli node services -name spark-master -action stop -nodes ${SPARK_MASTER_HOST}

sleep 5

#now, kill all the slaves
/opt/mapr/spark/spark-0.9.1/sbin/stop-slaves.sh

#kill shark
SS2_PID=`ps auxw|grep -i sharkserver2|grep -v grep|awk {'print $2'}`
echo ${SS2_PID}
echo "killing ${SS2_PID}"
kill -9 ${SS2_PID}

# now, kickoff spark-master
echo "starting spark-master up"
maprcli node services -name spark-master -action start -nodes ${SPARK_MASTER_HOST}
sleep 10

#kick off slaves
/opt/mapr/spark/spark-0.9.1/sbin/start-slaves.sh
sleep 10;

echo "starting sharkserver2"

/opt/mapr/shark/shark-0.9.0/bin/shark --service sharkserver2 &
disown
sleep 10;
echo "started everything up"
exit 0

