#env.sh for sparkstreaming => m7 demo


#clustername below works for the sandbox, you may need to change if you are running on something else

CLUSTER=demo.mapr.com
MYHOST=`hostname`
SPARK_URL=spark://${MYHOST}:7077
PORT=9999 

BATCHSECS=3 #length of spark streaming batches/DSTREAMs
TABLENAME=/tables/sensortable 

OUTFILE=/mapr/${CLUSTER}/CSV/sensor.csv

BASEDIR=/mapr/${CLUSTER}/ingest
DEMODIR=/mapr/${CLUSTER}/demos/spark-streaming-m7
JARFILE=${DEMODIR}/m7_streaming_import/target/scala-2.10/m7import_2.10-0.1-SNAPSHOT.jar

SOURCE_FILE=${BASEDIR}/SensorDataV5.csv
JAVA_BIN=`which java`
SLEEPSECS=.25 #sleep secs for data generator to pause between sending

#update path
export SHARK_BIN=/opt/mapr/shark/shark-0.9.0/bin/shark

#TODO: make some aliases
# #alias shark-beeline='${SHARK_BIN} --service beeline 
#  /opt/mapr/shark/shark-0.9.0/bin/shark --service beeline

#  !connect jdbc:hive2://localhost:10000 mapr mapr org.apache.hive.jdbc.HiveDriver
