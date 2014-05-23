#!/usr/bin/bash

#this script kill netcat if running, creates a FIFO, then uses that FIFO for the input for netcat.
# if does NOT push any data across the socket..that's "push_data.sh"

##the env.sh sets our variables, but if that isn't working you can uncomment and manually set them below.

. ./env.sh

# CLUSTER=summit2014
# BASEDIR=/mapr/${CLUSTER}/ingest
# SOURCE_FILE=${BASEDIR}/SensorDataV5.csv
# PORT=9999
# SLEEPSECS=.25
##


if [ -d /mapr/${CLUSTER} ]
	then
		if [ -f ${BASEDIR}/nc.pid ]
		then
			OLDPID=`cat ${BASEDIR}/nc.pid`
			kill -9 ${OLDPID}
			rm -f ${BASEDIR}/nc.pid
		fi

#add another check to kill if need be

if lsof -i:9999
	then
	killall -9 nc
fi

		mkdir -p ${BASEDIR}
		rm -f ${BASEDIR}/input_pipe
		mkfifo ${BASEDIR}/input_pipe
		tail -f ${BASEDIR}/input_pipe | nc -lk ${PORT} &
		PID=$!
		echo ${PID} > ${BASEDIR}/nc.pid
		disown
		echo "listener started w/ pid ${PID}, you are now ready to run the streaming app"

else
	echo "/mapr/${CLUSTER} isn't mounted, exiting"
	exit 1
fi


