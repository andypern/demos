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



ln -s /usr/bin/java /bin/java

echo 0 > /selinux/enforce
sed -i 's/=enforcing/=disabled/' /etc/selinux/config 

ssh-keygen -f /root/.ssh/id_rsa -t rsa -P ""
cp /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys


if ! rpm -qa | grep scala
	then	
	cd /tmp
	wget http://www.scala-lang.org/files/archive/scala-2.10.3.rpm
	rpm -ivh /tmp/scala-2.10.3.rpm
	rm -f /tmp/scala-2.10.3.rpm
fi

yum install -y lsof
yum install -y vim

yum install -y mapr-spark-master

#for now, grab impala too
yum install -y mapr-impala mapr-impala-server mapr-impala-statestore mapr-impala-catalog



/opt/mapr/server/configure.sh -R
echo "waiting 20 seconds for spark-master to startup"
sleep 20;
/opt/mapr/spark/spark-0.9.1/sbin/stop-slaves.sh

sleep 10

/opt/mapr/spark/spark-0.9.1/sbin/start-slaves.sh

 maprcli node services -name hs2 -action stop -nodes maprdemo


cp -f ${DEMODIR}/conf/hive-site.xml /opt/mapr/hive/hive-0.12/conf/hive-site.xml
cp -f ${DEMODIR}/conf/shark-env.sh /opt/mapr/shark/shark-0.9.0/conf/shark-env.sh
cp -f ${DEMODIR}/conf/spark-env.sh /opt/mapr/spark/spark-0.9.1/conf/spark-env.sh
cp -f ${DEMODIR}/conf/run /opt/mapr/shark/shark-0.9.0/run

#clean up old cruft

if [ -d ${BASEDIR} ]
	then
	if [ -f ${BASEDIR}/nc.pid ]
		then
		OLDPID=`cat ${BASEDIR}/nc.pid`
		kill -9 ${OLDPID}
		rm -f ${BASEDIR}/nc.pid
	fi
	if [ -f ${BASEDIR}/sharkserver2.pid ]
		then
		SS2_PID=`cat ${BASEDIR}/sharkserver2.pid`
		kill -9 ${SS2_PID}
	fi
	rm -rf ${BASEDIR}
fi


mkdir -p ${BASEDIR}

cp ${DEMODIR}/data/* ${BASEDIR}

cd ${DEMODIR}/m7_streaming_import

sbt/sbt package  

echo "all done prepping environment"