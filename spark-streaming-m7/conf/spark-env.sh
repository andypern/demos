	#!/usr/bin/env bash

# This file contains environment variables required to run Spark. Copy it as
# spark-env.sh and edit that to configure Spark for your site.
#
# The following variables can be set in this file:
# - SPARK_LOCAL_IP, to set the IP address Spark binds to on this node
# - MESOS_NATIVE_LIBRARY, to point to your libmesos.so if you use Mesos
# - SPARK_JAVA_OPTS, to set node-specific JVM options for Spark. Note that
#   we recommend setting app-wide options in the application's driver program.
#     Examples of node-specific options : -Dspark.local.dir, GC options
#     Examples of app-wide options : -Dspark.serializer
#
# If using the standalone deploy mode, you can also set variables for it here:
# - SPARK_MASTER_IP, to bind the master to a different IP address or hostname
# - SPARK_MASTER_PORT / SPARK_MASTER_WEBUI_PORT, to use non-default ports
# - SPARK_WORKER_CORES, to set the number of cores to use on this machine
# - SPARK_WORKER_MEMORY, to set how much memory to use (e.g. 1000m, 2g)
# - SPARK_WORKER_PORT / SPARK_WORKER_WEBUI_PORT
# - SPARK_WORKER_INSTANCES, to set the number of worker processes per node
# - SPARK_WORKER_DIR, to set the working directory of worker processes

export CLUSTER=`head -n 1 /opt/mapr/conf/mapr-clusters.conf |awk {'print $1'}`
export SPARK_SCRATCH=/mapr/$CLUSTER/var/mapr/local/`cat /opt/mapr/hostname`/sparktmp

export SPARK_HOME=/opt/mapr/spark/spark-0.9.1
export HADOOP_HOME=/opt/mapr/hadoop/hadoop-0.20.2
export SPARK_LIBRARY_PATH=/usr/local/lib:/opt/mapr/lib:/opt/mapr/hadoop/hadoop-0.20.2/lib/native/Linux-amd64-64

SPARK_CLASSPATH=$SPARK_CLASSPATH:/opt/mapr/lib/json-20080701.jar:/opt/mapr/hadoop/hadoop-0.20.2/conf:/opt/mapr/hadoop/hadoop-0.20.2/lib/hadoop-0.20.2-dev-core.jar:/opt/mapr/hadoop/hadoop-0.20.2/lib/commons-logging-1.0.4.jar:/opt/mapr/lib/libprotodefs.jar:/opt/mapr/lib/maprutil-0.1.jar:/opt/mapr/lib/baseutils-0.1.jar:/opt/mapr/hbase/hbase-0.94.17/conf/:/opt/mapr/hadoop/hadoop-0.20.2/lib/maprfs-1.0.3-mapr-3.0.3.jar:/opt/mapr/hadoop/hadoop-0.20.2/lib/zookeeper-3.3.6.jar:/opt/mapr/hadoop/hadoop-0.20.2/lib/mapr-hbase-1.0.3-mapr-3.0.3.jar:/opt/mapr/hbase/hbase-0.94.17/hbase-0.94.17-mapr-1405.jar:


export SPARK_CLASSPATH
export SPARK_WORKER_DIR=${SPARK_SCRATCH}/worker_dir

#export SPARK_JAVA_OPTS+=" -Dspark.local.dir=/mapr/my.cluster.com/var/mapr/local/`hostname -s`/sparktmp"

#
# MASTER HA SETTINGS
#
#export SPARK_DAEMON_JAVA_OPTS="-Dspark.deploy.recoveryMode=ZOOKEEPER  -Dspark.deploy.zookeeper.url=<zookeerper1:5181,zookeeper2:5181,..>"

# MEMORY SETTINGS
export SPARK_MEM=1g
export SPARK_DAEMON_MEMORY=1g
export SPARK_WORKER_MEMORY=6g
export SPARK_JAVA_OPTS+=" -Dspark.cores.max=4"
export SPARK_JAVA_OPTS+=" -Dspark.local.dir=${SPARK_SCRATCH}/localdir"


export SPARK_MASTER_IP=REPLACEME

