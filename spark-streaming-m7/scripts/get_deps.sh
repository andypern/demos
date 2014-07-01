#!/bin/bash


if [ -f ${DEMODIR}/scripts/global_env.sh ]
	then
	source ${DEMODIR}/scripts/global_env.sh
elif [ -f ./global_env.sh ]
	then
	source ./global_env.sh
else
	echo "global_env.sh not sourced, you need to chdir to /mapr/clustername/demos/spark-streaming-m7/scripts and run this from there."
	exit 1
fi



ln -s /usr/bin/java /bin/java

# echo 0 > /selinux/enforce
# sed -i 's/=enforcing/=disabled/' /etc/selinux/config 

# ssh-keygen -f /root/.ssh/id_rsa -t rsa -P ""
# cp /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys


if ! rpm -qa | grep scala
	then	
	cd /tmp
	wget http://www.scala-lang.org/files/archive/scala-2.10.3.rpm
	clush -a -c /tmp/scala-2.10.3.rpm
	clush -a "rpm -ivh /tmp/scala-2.10.3.rpm"
	clush -a "rm -f /tmp/scala-2.10.3.rpm"
fi

clush -a "yum install -y lsof telnet"
clush -a "yum install -y vim"

#create local volumes on all nodes for spark to use for tmp

clush -a 'maprcli volume create -name mapr.`cat /opt/mapr/hostname`.local.sparktmp -path /var/mapr/local/`cat /opt/mapr/hostname`/sparktmp -replication 1 -localvolumehost `cat /opt/mapr/hostname` -localvolumeport 5660'

yum install -y mapr-spark-master
clush -a "yum install -y mapr-spark"

#for now, grab impala too
#clush -a "yum install -y mapr-impala mapr-impala-server"

#yum install -y mapr-impala-statestore mapr-impala-catalog

#populate the slaves file

echo ${NODELIST} > /opt/mapr/spark/spark-0.9.1/conf/slaves
clush -a -c /opt/mapr/spark/spark-0.9.1/conf/slaves


clush -a "/opt/mapr/server/configure.sh -R"
echo "waiting 20 seconds for spark-master to startup"
sleep 20;
/opt/mapr/spark/spark-0.9.1/sbin/stop-slaves.sh

sleep 10

/opt/mapr/spark/spark-0.9.1/sbin/start-slaves.sh

 # maprcli node services -name hs2 -action stop -nodes maprdemo

#fix some configs
sed -i 's/REPLACEME/'${MYHOST}'/' ${DEMODIR}/conf/spark-env.sh

sed -i 's/REPLACEME/'${MYHOST}'/' ${DEMODIR}/conf/shark-env.sh


cp /opt/mapr/hive/hive-0.13/conf/hive-site.xml /opt/mapr/hive/hive-0.13/conf/hive-site.xml.bak

cp -f ${DEMODIR}/conf/hive-site.xml /opt/mapr/hive/hive-0.13/conf/hive-site.xml
cp -f ${DEMODIR}/conf/shark-env.sh /opt/mapr/shark/shark-0.9.0/conf/shark-env.sh

clush -a -c /opt/mapr/shark/shark-0.9.0/conf/shark-env.sh



cp -f ${DEMODIR}/conf/spark-env.sh /opt/mapr/spark/spark-0.9.1/conf/spark-env.sh
clush -a -c /opt/mapr/spark/spark-0.9.1/conf/spark-env.sh

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

#prebuild the package to grab all the dep's, then copy into place
cd ${DEMODIR}/m7_streaming_import

sbt/sbt package  

#set SHARK_HOST by grabbing the last line out of /etc/hosts

SHARK_HOST=`tail -n 1 /etc/hosts | awk {'print $2'}
sed -i 's/REPLACESHARKHOST/${SHARK_HOST}/' ${DEMODIR}/scripts/env.sh

#user dirs

for USER in `seq 9`
	do echo "user${USER}"
	mkdir -p /mapr/${CLUSTER}/user/user${USER}/spark
	cp -R ${DEMODIR}/* /mapr/${CLUSTER}/user/user${USER}/spark
	#FIX UP HQL FILES
	
	sed -i 's/USERNAME/user'${USER}'/g' /mapr/${CLUSTER}/user/user${USER}/spark/scripts/*.hql
	sed -i 's/CLUSTER/'${CLUSTER}'/g' /mapr/${CLUSTER}/user/user${USER}/spark/scripts/*.hql
	
	#Fix up env.sh
	
	sed -i 's/REPLACEURL/'${MYHOST}'/' /mapr/${CLUSTER}/user/user${USER}/spark/scripts/env.sh
	sed -i 's/REPLACEUSER/user'${USER}'/' /mapr/${CLUSTER}/user/user${USER}/spark/scripts/env.sh
	sed -i 's/REPLACEPORT/999'${USER}'/' /mapr/${CLUSTER}/user/user${USER}/spark/scripts/env.sh


done


# mkdir -p ${BASEDIR}

# cp ${DEMODIR}/data/* ${BASEDIR}


# echo "all done prepping environment"