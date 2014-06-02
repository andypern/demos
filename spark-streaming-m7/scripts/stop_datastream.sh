#!/usr/bin/bash
source ./env.sh

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