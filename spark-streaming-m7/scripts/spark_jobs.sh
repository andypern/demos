#!/bin/bash

if [ -f $LABDIR/spark/scripts/env.sh ]
	then
	source ${LABDIR}/spark/scripts/env.sh
elif [ -f ./env.sh ]
	then
	source ./env.sh
else
	echo "env.sh not sourced, you need to chdir to /mapr/clustername/user/username/spark/scripts and run this from there."
	exit 1
fi

if [ -n "$1" ]
	then CLASS=$1
else
	echo "you didn't specify a class!" >&2
	echo "usage: spark_jobs.sh ClassName extra-args" >&2
	echo "available classes: SparkPi JavaWordCount" >&2
	echo "example: spark_jobs.sh JavaWordCount /mapr/clustername/username/spark/data/input.txt" >&2
	exit 1
fi


/opt/mapr/spark/spark-0.9.1/bin/run-example \
org.apache.spark.examples.${CLASS} \
${SPARK_URL} \
$2 > ${LABDIR}/spark/output/job.output.txt
