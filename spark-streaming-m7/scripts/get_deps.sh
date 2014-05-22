#!/bin/bash
echo 0 > /selinux/enforce
ssh-keygen -f /root/.ssh/id_rsa -t rsa -P ""
cp /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys

cd /tmp
wget http://www.scala-lang.org/files/archive/scala-2.10.3.rpm
rpm -ivh /tmp/scala-2.10.3.rpm
rm -f /tmp/scala-2.10.3.rpm

yum install -y lsof

yum install -y mapr-spark-master


/opt/mapr/server/configure.sh -R
/opt/mapr/spark/spark-0.9.1/sbin/start-slaves.sh

 maprcli node services -name hs2 -action stop -nodes maprdemo


cp -f /mapr/demo.mapr.com/demos/spark-streaming-m7/conf/hive-site.xml /opt/mapr/hive/hive-0.12/conf/hive-site.xml
cp -f /mapr/demo.mapr.com/demos/spark-streaming-m7/conf/shark-env.sh /opt/mapr/shark/shark-0.9.0/conf/shark-env.sh
cp -f /mapr/demo.mapr.com/demos/spark-streaming-m7/conf/run /opt/mapr/shark/shark-0.9.0/run


mkdir -p /mapr/demo.mapr.com/ingest

cp ../data/* /mapr/demo.mapr.com/ingest

cd ../m7_streaming_import

sbt/sbt package  

echo "all done prepping environment"