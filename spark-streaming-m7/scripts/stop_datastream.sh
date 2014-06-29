#!/usr/bin/bash

if [ -f ${LABDIR}/scripts/env.sh ]
    then
    source ${LABDIR}/scripts/env.sh
elif [ -f ./env.sh ]
    then
    source env.sh
else
    echo "env.sh not sourced, you need to chdir to /mapr/clustername/user/username/spark/scripts and run this from there."
    exit 1
fi






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