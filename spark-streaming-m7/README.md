#Shark, Spark, M7
This is a work in progress...

##TODO

* Fork for sandbox instructions (can 3.1 be used...need EBF patch also?)
* add some screenshots to this doc
* simplify the procedure (put more logic into the shell scripts)
* wrap sharkserver2 startup
* Add visualization for realtime (e.g.: dispatch to D3/etc prior to insertion into M7)
* use Kafka instead of netcat..

##Overview

The goal of this demo is to show users how to use MapR, in conjunction with spark, shark, and MapR-tables (M7) to :

* ingest data using network transport (socket)
*  spark-streaming to load data into m7-table
* Use shark to query data , both from M7, as well as from flat files (csv)
* Leverage ODBC drivers to allow Tableau to access data in M7



## Pre-requisites

###Client/windows host

* Windows7 or 2008_server_R2 or above
* NFS client configured 
* Tableau 8.1 installed
* Shark ODBC driver installed: https://drive.google.com/a/maprtech.com/file/d/0B2LQncH-ZgnwcVRnZDV3Wjdsd2c/edit?usp=sharing




###v3.0.3 sandbox
If you are using a 3.0.3 Sandbox, you can follow these shorter directions.  If not, skip to "Nodes that are NOT.."


1. Install git:

		yum install -y git
2.  Go to your NFS loopback mount:

		cd /mapr/demo.mapr.com
		
3.  Grab the entire demos repo (for now..):

		git clone https://github.com/andypern/demos

4.	Go to the scripts directory in our specific demo folder:

		cd demos/spark-streaming-m7/scripts

5. ***only works on 3.0.3 sandbox***: run dependency installer:

		sh ./get_deps.sh
>this will take several minutes or more.


**Now skip down to the "Edit Variables" section.**



###Nodes that are NOT the 3.0.3 sandbox



* MapR 3.0.3 , with m7 license.  These instructions were written with the 3.0.3 Sandbox VM in mind (http://package.mapr.com/releases/v3.0.3/sandbox/), but can be adapted to work on any 3.0.3 cluster.
* localhost/loopback mounts are working.
* mapr-hbase should be installed on all nodes (so that the HBASE client jars are in place)
* mapr-hivemetastore should be installed on the node you will be working on (referred to as node-1 here)
* make sure that hs2 (hiveserver2) is NOT running on node-1. EG: stop the service from MCS if need be.
* mapr-hive should be installed on all nodes (just in case) in order to get client jars
* mysql backend for hivemetastore is optional.
* If you are running any version other than 3.0.3, you will need the appropriate EBF patch from yum.qa.lab
* install git
* install lsof
* shark + spark installed as per https://docs.google.com/a/maprtech.com/document/d/1WbyM-0RCWhCRdVrkGO5MKevWXz5U2hwWjalQGRhDHr4
* ssh keys setup so node-1 can ssh w/out password to other nodes.
* make a symlink (needed for some scala/spark/shark things):

		 ln -s /usr/bin/java /bin/java
		 


####Shark specifics

The docs for installing shark+spark are mostly complete, but if you want to use shark with M7 you'll need to do a little extra.

1.  First, dump this into hive-site.xml (***If you are NOT using the 3.0.3 sandbox, make sure to modify hbase+hive paths to reflect proper version #'s, also make sure to put the proper zk quorum nodes in..***):


		<!--this is to get shark to work w/ m7-->
		<property>
		<name>hive.aux.jars.path</name>
		   <value>file:///opt/mapr/hive/hive-0.12/lib/hive-hbase-handler-0.12-mapr-1403.jar,file:///opt/mapr/hbase/hbase-0.94.17/hbase-0.94.17-mapr-1403-SNAPSHOT.jar,file:///opt/mapr/zookeeper/zookeeper-3.3.6/zookeeper-3.3.6.jar</value>
		   <description>A comma separated list (with no spaces) of the jar files required for Hive-HBase integration</description>
		 </property>
		
		<property>
		  <name>hbase.zookeeper.quorum</name>
		  <value>maprdemo</value>
		  <description>A comma separated list (with no spaces) of the IP addresses of all ZooKeeper servers in the cluster.</description>
		</property>
		
		 <property>
		  <name>hbase.zookeeper.property.clientPort</name>
		  <value>5181</value>
		  <description>The Zookeeper client port. The MapR default clientPort is 5181.</description>
		 </property>
  
 
 
 2.  Copy that to all nodes for good measure (***not required for single-node environments***):
 
		 clush -a -c /opt/mapr/hive/hive-0.12/conf/hive-site.xml
 
 3.  We have to trick the shark 'run' parameters a little, and insert a hive jar into the class path manually. 

		vim /opt/mapr/shark/shark-0.90/run 
	>edit line 63, but make sure you load this AFTER the lib_managed jars get loaded:
  

		  SPARK_CLASSPATH+=:/opt/mapr/hive/hive-0.12/lib/hive-exec-0.12-mapr-1403.jar


* Make sure you can get to the spark UI (on port 8080), and that you can fire off slaves/workers successfully.
* Also take note of the spark URL (spark://hostname:7077) EXACTLY, as you'll need it later.


###Demo code prep  




2.  Go to your NFS loopback mount:

		cd /mapr/demo.mapr.com
		
3.  Grab the entire demos repo (for now..):

		git clone https://github.com/andypern/demos


5.  Make a folder where our dataset and some other related files will live:

		mkdir -p /mapr/demo.mapr.com/ingest

6.  Copy the various CSV files we'll be using into place:

		 cp data/* /mapr/demo.mapr.com/ingest

7. Change directories to where our SCALA code lives:

		 cd m7_streaming_import

8.  Use SBT to package the JAR:

		sbt/sbt package  
	>(this might take a few minutes)





	

  



###Edit variables


1.  Open a new SSH session to the node you've been working on

2. 	Go into the directory containing the shell scripts for this demo:

		cd /mapr/demo.mapr.com/demos/spark-streaming-m7/scripts

3.	Modify the `env.sh` script.  If you are NOT using the sandbox, you will need to change the CLUSTER value.  The SLEEPSECS variable tells the script how long to wait between sending lines to the network socket.  .25 seconds means that 4 lines/second will be sent.  The SPARK_URL may need modifying depending on how your dns or /etc/hosts is setup.  Obtain the EXACT SPARK_URL by navigating to http://hostname:8080 in a web-browser, and looking for the appropriate line.

***NOTE*** : Do not change the TABLENAME or BASEDIR variables....unless you want things to break (if you like troubleshooting, then you'll need to change some paths in the *hql files as well)


			
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


###Pre-create the hive tables/views we'll be using

1.  In a terminal window, go to the scripts folder:

		cd /mapr/demo.mapr.com/demos/spark-streaming-m7/scripts

2.  Run the create_tables.sh script:

		sh ./create_tables.sh




##Running the demo

###Populating tables

1.  Make sure you have 3 terminal windows ssh'd into the cluster, where you've cd'd into the following directory:

			

2.  In 'terminal-1', launch the data stream generator:

		sh ./launch_datastream.sh
>the output to the screen will be CSV data as it is streamed to the network socket.

3.  In 'terminal-2', launch the spark-streaming script (which will pull data into M7): 

		sh ./run_m7_streaming_import.sh 
>the output will indicate how many rows were inserted into M7 and persisted on disk.  The interval is controlled by the BATCHSECS variable.  


4.  Wait for 60 seconds so that some data can populate.  In 'terminal-3' we're going to look at the table and make sure that data is appearing:


		hbase shell


		>scan '/tables/sensortable', {LIMIT => 5}
> hit 'crtl-d' to exit this prompt

###External access to tables
		
In order for other applications (shark, and subsequently, tableau) to get access to the data inside of M7, we'll make use of external tables which are defined in the hive metastore.  All tables and views were pre-created in a previous step, so now we just want to verify that they are working.


All work here is done in 'terminal-3'


1.  Verify that you can run shark against this table and see data:

		/opt/mapr/shark/shark-0.9.0/bin/shark -e "select * from sensor limit 10;"

2.  Kick off sharkserver2 so we can get access via ODBC/etc:

		/opt/mapr/shark/shark-0.90/bin/shark --service sharkserver2 &
		disown

3.  Verify that you can connect to it via JDBC:

		/opt/mapr/shark/shark-0.90/bin/shark --service beeline
		!connect jdbc:hive2://localhost:10000 root mapr org.apache.hive.jdbc.HiveDriver
		 show tables;
>press crtl-d to exit the beeline shell.

Now that you've shown that the data is accessible via SHARK queries, its time to move on to tableau.


##Everything below doesn't work










### Tableau

(***5-10 mins***)

Switch to your windows desktop, and open the Tableau window.

* choose the datasource (already preconfigured), explain how this is initiating an ODBC connection to MapR
* Browse through sheets in tableu (pre-made).  Explain how each sheet/chart is generated by a series of SQL queries which tableau issues to mapR, and how user interactivity is dependent on fast response time to queries.

	* pump vendor differences (which have best flow-rate and/or pressure)
	* all pumps on a timeline, showing the peaks/valleys of the pressure and flow rates
	* isolate one specific pump which has dropped its pressure entirely
	* drag the 'displace' measurement and describe what it is (vibration)
	* once the screen redraws, show that when displacement reaches too high of a value, directly afterwards the pump pressure drops to zero
	* reselect other pumps to see if any others are starting to exhibit high displacement rates, or low pressure.


Q+A and closing.






## Appendix

*** dataset story: preventative maintenance @ oil fields.  detect anomalies, ingested in realtime.
find anomalies: one is a complete pump failure, you'll see a rise in vibration and drop in flow rate or pressure.  , one is a condition based maintenance, where you see vibration going up, flow rate going down.  

only 1 of the pumps actually fails: nantahala, one pump follows the pattern, but doesn't quite break : cohutta.

HZ=electrical current.

first look @ failed pump, see what happened on a timeline.

displacement is high (3+) and is low (70-), we might be seeing a failure.

pressure should be 70+

flow = production rate.

each average flow rate is different per brand.
vibration/displacement is different per brand.

the failed pump and the almost failed pump are both made by hydrocam.

pie chart that shows 'green' pumps, 'yellow' pumps, and 'red' pumps. based on displacement and/or pressure.


