#!/usr/bin/bash

##TODO
# * instead of blowing away/re-creating the table each run,  perhaps just create a bunch of tables..one for each iteration?
# * elegantly check if spark workers are running.

##the env.sh sets our variables

if [ -f ${LABDIR}/scripts/env.sh ]
	then
	source ${LABDIR}/scripts/env.sh
elif [ -f ./env.sh ]
	then
	source ./env.sh
else
	echo "env.sh not sourced, you need to chdir to /mapr/clustername/user/username/spark/scripts and run this from there."
	exit 1
fi




####first, check if things are mounted properly..and bomb out if not

if [ ! -d /mapr/${CLUSTER} ]
	then
	echo "/mapr/${CLUSTER} not mounted, quitting"
	exit 1
fi

####check if our netcat socket is open

if ! lsof -i:${PORT}
	then
	echo "port ${PORT} isn't listening..perhaps you need to start the start_listener.sh script"
	exit 1
fi

#### check if spark is running on 7077

# if ! lsof -i:7077
# 	then
# 	echo "spark isn't listening on port 7077, you may need to start it from MCS"
# 	exit 1
# fi

####TODO: check if spark workers are running on at least one node..


###delete table if it exists

# if [ -L /mapr/${CLUSTER}/${TABLENAME} ]
# 	then
# 		echo "deleting existing table /mapr/${CLUSTER}/${TABLENAME}"
# 		rm -f  /mapr/${CLUSTER}/${TABLENAME}
# fi

###Create a new table and CF if one doesnt exist

if ! [ -L ${TABLEPATH} ]
	then
	mkdir -p ${LABDIR}/tables

	maprcli table create -path ${TABLEPATH}
	maprcli table cf create -path ${TABLEPATH} -cfname cf1
	echo "created ${TABLENAME} and CF:cf1"
fi


###blow away CSV file
if [ -e ${OUTFILE} ]
	then
	rm -f ${OUTFILE}
fi
##create directory if need be

mkdir -p /mapr/${CLUSTER}/CSV


###blow away the JSON output file

if [ -e ${D3_OUTPUT} ]
	then
	rm -f ${D3_OUTPUT}
fi



export SHARK_HOME=/opt/mapr/shark/shark-0.9.0
export SPARK_HOME=/opt/mapr/spark/spark-0.9.1
export SCALA_HOME=/usr/share/java
export CLASSPATH


###Jars for our app###
#first, use the JAR we care about
CLASSPATH+=${JARFILE}

#next, grab jars from mapR spark + shark folders

for jar in `find $SPARK_HOME -name '*.jar'`; do
	CLASSPATH+=:$jar
done

for jar in `find $SHARK_HOME/lib_managed -name '*.jar'`; do
	CLASSPATH+=:$jar
done


####MapR stuff
 for jar in `find /opt/mapr/hadoop -name '*.jar'`;do
         CLASSPATH+=:$jar
 done

 for jar in `find /opt/mapr/hbase -name '*.jar'`;do
         CLASSPATH+=:$jar
 done

####end MapR stuff 

#grab JARS from scala dir

for jar in `find $SCALA_HOME -name 'scala*.jar'`; do
	CLASSPATH+=:$jar
done

#grab the json4s jars
if [ -d ${LABDIR}/m7_streaming_import/jars/cache/org.json4s ]
	then
	for jar in `find ${DEMODIR}/m7_streaming_import/jars/cache/org.json4s -name '*.jar'`; do
	CLASSPATH+=:$jar
	done
else
	echo "you may need to recompile the app via sbt/sbt package...json4s jars not found"
	exit 1
fi


#grab our special spray jar

#CLASSPATH+=:${SCALA_HOME}/spray-json_2.11-1.2.6.jar

# Add in the mapR FS jar

CLASSPATH+=:/opt/mapr/lib/maprfs-1.0.3-mapr-3.0.3.jar

#finally, execute the code

${JAVA_BIN} -cp $CLASSPATH org.apache.spark.streaming.m7import.m7import ${SPARK_URL} ${MYHOST} ${PORT} ${USERNAME} ${BATCHSECS} ${TABLEPATH} ${OUTFILE} ${D3_OUTPUT}