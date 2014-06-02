#!/usr/bin/bash

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


BASEDIR=/mapr/${CLUSTER}/ingest



#first , kill the listener off
if [ -d /mapr/${CLUSTER} ]
    then
        if [ -f ${BASEDIR}/nc.pid ]
        then    
            OLDPID=`cat ${BASEDIR}/nc.pid`
            kill -9 ${OLDPID}
            echo "killed ${OLDPID}"
        fi      
    #killall for good measure
    killall -9 nc
    # remove the pidfile
    rm -f ${BASEDIR}/nc.pid
else
    echo "/mapr/${CLUSTER} isn't mounted, exiting"
    exit 1
fi