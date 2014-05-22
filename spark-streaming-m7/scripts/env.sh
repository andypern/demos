#env.sh for sparkstreaming => m7 demo


#clustername below works for the sandbox, change if you are running on something else

CLUSTER=demo.mapr.com
MYHOST=`hostname`
SPARK_URL=spark://${MYHOST}:7077
PORT=9999 

BATCHSECS=3 #length of spark streaming batches/DSTREAMs
TABLENAME=/tables/sensortable 
OUTFILE=/mapr/${CLUSTER}/CSV/sensor.csv
JARFILE=/mapr/${CLUSTER}/demos/spark-streaming-m7/m7_streaming_import/target/scala-2.10/m7import_2.10-0.1-SNAPSHOT.jar
BASEDIR=/mapr/${CLUSTER}/ingest
SOURCE_FILE=${BASEDIR}/SensorDataV5.csv

SLEEPSECS=.25 #sleep secs for data generator to pause between sending