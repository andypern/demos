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

/opt/mapr/spark/spark-0.9.1/bin/run-example org.apache.spark.examples.WordCount spark://ip-10-230-4-141.us-west-2.compute.internal:7077