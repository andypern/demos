#!/usr/bin/bash
CLUSTER=summit2014


BASEDIR=/mapr/${CLUSTER}/ingest



#first , kill the listener off
if[-d /mapr/${CLUSTER}]
	then
		if [ -f ${BASEDIR}/nc.pid ]
		then
			OLDPID=`cat ${BASEDIR}/nc.pid`
			kill -9 ${OLDPID}
			echo "killed ${OLDPID}"
		fi
else
	echo "/mapr/${CLUSTER} isn't mounted, exiting"
	exit 1
fi


