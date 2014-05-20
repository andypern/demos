#!/usr/bin/bash


##Set some variables
CLUSTER=summit2014


BASEDIR=/mapr/${CLUSTER}/ingest
SOURCE_FILE=${BASEDIR}/SensorDataV5.csv

PORT=9999
SLEEPSECS=.25
##


if[-d /mapr/${CLUSTER}]
	then
		if [ -f ${BASEDIR}/nc.pid ]
		then
			OLDPID=`cat ${BASEDIR}/nc.pid`
			kill -9 ${OLDPID}
		fi

		mkdir -p ${BASEDIR}
		rm -f ${BASEDIR}/input_pipe
		mkfifo ${BASEDIR}/input_pipe
		tail -f ${BASEDIR}/input_pipe | nc -lk ${PORT} &
		PID=$!
		echo ${PID} > ${BASEDIR}/nc.pid
		disown
		echo "listener started w/ pid ${PID}, commencing datastream..go start your spark-streaming app NOW"
		echo "hit crtl-c to kill, then run the stop_datastream.sh script to make sure.."
		for line in `cat ${SOURCE_FILE}| sort -k2 -k3 -t $',' `
			do
			echo ${line} | tee -a ${BASEDIR}/input_pipe 
			sleep ${SLEEPSECS}
		done

else
	echo "/mapr/${CLUSTER} isn't mounted, exiting"
	exit 1
fi


