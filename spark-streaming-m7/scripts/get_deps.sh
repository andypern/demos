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

#fix sysconfig/network

clush -a 'sed -r -i "s/HOSTNAME\=.+/HOSTNAME\='\`cat /opt/mapr/hostname\`'/" /etc/sysconfig/network'


clush -a 'yum install -y mapr-hive-0.12.26066-1'
yum install -y mapr-hivemetastore-0.12.26066-1
clush -a 'yum install -y mapr-hbase'
clush -a 'yum install -y mysql'
clush -a -c /etc/clustershell/groups
clush -a -c /etc/hosts
clush -a 'echo "mapr" | passwd --stdin root'
clush -a 'echo "mapr" | passwd --stdin mapr'
clush -a 'yum install -y lsof git screen'

export MYSQLHOST=`clush -a 'netstat -an|grep 3306|grep LISTEN' 2>/dev/null|awk -F ":" {'print $1'}`

ssh $MYSQLHOST 'mysql -u root -e "drop user 'mapr'@'localhost';"'
ssh $MYSQLHOST 'mysql -u root -e "drop user 'mapr'@'%';"'
ssh $MYSQLHOST 'mysql -u root -e "drop user 'mapr'@'localhost';"'
ssh $MYSQLHOST 'mysql -u root -e "drop user 'mapr'@'%';"'
ssh $MYSQLHOST 'mysql -u root -e "create user 'mapr'@'%' identified by 'MapR';"'
ssh $MYSQLHOST 'mysql -u root -e "GRANT ALL PRIVILEGES ON *.* TO 'mapr'@'%' WITH GRANT OPTION;"'

cd /tmp
curl -L 'http://www.mysql.com/get/Downloads/Connector-J/mysql-connector-java-5.1.18.tar.gz/from/http://mysql.he.net/|http://mysql.he.net/' | tar xz
cp mysql-connector-java-5.1.18/mysql-connector-java-5.1.18-bin.jar /opt/mapr/hive/hive-0.12/lib
clush -a -c /opt/mapr/hive/hive-0.12/lib/mysql-connector-java-5.1.18-bin.jar 

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


cp /opt/mapr/hive/hive-0.12/conf/hive-site.xml /opt/mapr/hive/hive-0.12/conf/hive-site.xml.bak

cp -f ${DEMODIR}/conf/hive-site.xml /opt/mapr/hive/hive-0.12/conf/hive-site.xml
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

SHARK_HOST=`tail -n 1 /etc/hosts | awk {'print $2'}`
sed -i 's/REPLACESHARKHOST/'${SHARK_HOST}'/' ${DEMODIR}/scripts/env.sh

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


#time to fix up the hive-site.xml

export HIVEMETA=`maprcli node list -columns hostname,csvc -filter csvc=="hivemeta"|tail -n 1 | awk {'print $1'}`
export ZK_QUORUM=`grep zk /etc/clustershell/groups|awk {'print $2'}`
export MYSQLHOST=`clush -a 'netstat -an|grep 3306|grep LISTEN' 2>/dev/null|awk -F ":" {'print $1'}`

sed -i 's/REPLACE_META/'${HIVEMETA}'/' /opt/mapr/hive/hive-0.12/conf/hive-site.xml
sed -i 's/REPLACE_ZK/'${ZK_QUORUM}'/' /opt/mapr/hive/hive-0.12/conf/hive-site.xml
sed -i 's/REPLACE_MYSQL/'${MYSQLHOST}'/' /opt/mapr/hive/hive-0.12/conf/hive-site.xml

clush -a -c /opt/mapr/hive/hive-0.12/conf/hive-site.xml



echo "time for drill"

cd /mapr/$CLUSTER
wget http://54.184.26.48/mapr-drill-1.0.0.BETA1.26376-1.noarch.rpm
clush -a "rpm -ivh /mapr/$CLUSTER/mapr-drill-1.0.0.BETA1.26376-1.noarch.rpm"

echo -e "\nexport HADOOP_HOME=/opt/mapr/hadoop/hadoop-0.20.2" >> /opt/mapr/drill/drill-1.0.0.BETA1/conf/drill-env.sh

clush -a -c /opt/mapr/drill/drill-1.0.0.BETA1/conf/drill-env.sh

export ZK_QUORUM=`grep zk /etc/clustershell/groups|awk {'print $2'}`
export ZK_PORTS=`echo $ZK_QUORUM|sed 's/,/:5181,/g'|sed 's/$/:5181/'`
sed -i 's/localhost:2181/'$ZK_PORTS'/' /opt/mapr/drill/drill-1.0.0.BETA1/conf/drill-override.conf 
clush -a -c /opt/mapr/drill/drill-1.0.0.BETA1/conf/drill-override.conf
clush -a 'mkdir -p /opt/mapr/zookeeper/zookeeper-3.3.6/'

clush -a -c /opt/mapr/zookeeper/zookeeper-3.3.6/zookeeper-3.3.6.jar


maprcli node services -name drill-bits -action restart -nodes $(maprcli node list -columns hn -filter csvc=="drill-bits" | tail -n +2 | cut -d' ' -f1)

sleep 30;

clush -a 'jps|grep -i drill'


#elasticsearch
yum install -y httpd

cd /tmp
wget https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-1.2.1.noarch.rpm

rpm -i elasticsearch-1.2.1.noarch.rpm

service elasticsearch start


CURLSTATUS=` curl 'http://localhost:9200/?pretty' 2>/dev/null|grep status|grep 200|wc -l`

if [ $CURLSTATUS = 0 ] 
then
	echo “exiting, curlstatus not OK, check elasticsearch service”
	exit 1
fi

wget https://download.elasticsearch.org/kibana/kibana/kibana-3.1.0.zip

unzip kibana-3.1.0.zip 
cp -R kibana-3.1.0 /var/www/html/ 

sed -i -r "s/\"\+window\.location\.hostname\+\"/`hostname -a|awk {'print $2'}`/" /var/www/html/kibana-3.1.0/config.js 

service httpd start

DASH_STATUS=curl http://skohearts0/kibana-3.1.0/#/dashboard/file 2>/dev/null|grep Kibana|wc -l

if [ $DASH_STATUS = 0 ] 
then
	echo “exiting, DASH_STATUS not OK, check httpd service”
	exit 1
fi

wget http://download.elasticsearch.org/hadoop/elasticsearch-hadoop-2.0.0.zip

unzip elasticsearch-hadoop-2.0.0.zip 

cp /tmp/elasticsearch-hadoop-2.0.0/dist/elasticsearch-hadoop-hive-2.0.0.jar /opt/mapr/hive/hive-0.12/lib/


cp /tmp/elasticsearch-hadoop-2.0.0/dist/elasticsearch-hadoop-2.0.0.jar /opt/mapr/hive/hive-0.12/lib/

clush -a -c /opt/mapr/hive/hive-0.12/lib/elasticsearch*.jar

yum install -y python tools
easy_install pip
easy_install tweepy
pip install elasticsearch

mkdir -p /mapr/$CLUSTER/user/*/elasticsearch/data



# fix cluster name in braden's py scripts.


# fix usernames for each folder
# fix sko1/cluster name for each folder
# fix es.resource to not be ip-* (needs to be host that is running elasticsearch)

# need to run:
# hive -f /mapr/skohearts/user/user1/elasticsearch/meta/teams_hive.txt
# on each elasticsearch node

export HOSTNAME=`hostname -a|awk {'print $2'}`

find /mapr/$CLUSTER/demos/elasticsearch-SKO -name "*.py" -exec sed -r -i 's/REPLACE_CLUSTER/'$CLUSTER'/' {} \;

find /mapr/$CLUSTER/demos/elasticsearch-SKO -type f -exec sed -r -i 's/REPLACE_HOST/'$HOSTNAME'/' {} \; 

cp -R /mapr/$CLUSTER/demos/elasticsearch-SKO/* /mapr/$CLUSTER/user/

hive -f /mapr/$CLUSTER/user/user1/elasticsearch/meta/teams_hive.txt




/usr/share/elasticsearch/bin/plugin --install mobz/elasticsearch-head

#

# mkdir -p ${BASEDIR}

# cp ${DEMODIR}/data/* ${BASEDIR}


# echo "all done prepping environment"