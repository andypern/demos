#Shark, Spark, M7
This is a work in progress...

##TODO


* add some screenshots to this doc
* ~~simplify the procedure (put more logic into the shell scripts)~~
* ~~wrap sharkserver2 startup~~
* Add visualization for realtime (e.g.: dispatch to D3/etc prior to insertion into M7)
* use Kafka instead of netcat..

##Overview

The goal of this demo is to show users how to use MapR, in conjunction with spark, shark, and MapR-tables (M7) to :

* ingest data using network transport (socket)
* spark-streaming to load data into m7-table
* Use shark to query data , both from M7, as well as from flat files (csv)
* Leverage ODBC drivers to allow Tableau to access data in M7



## Pre-requisites

###Client/windows host

* Windows7 or 2008_server_R2 or above
* NFS client configured 
* Tableau 8.1 installed
* Shark ODBC driver installed: https://drive.google.com/a/maprtech.com/file/d/0B2LQncH-ZgnwcVRnZDV3Wjdsd2c/edit?usp=sharing




###v3.0.3 sandbox
If you are using a 3.0.3 Sandbox, you can follow these shorter directions.  If not, skip to `Nodes that are NOT the 3.0.3 sandbox`

All instructions assume that you login as root (password=mapr on the sandbox)

1.  You must increase the # of cores that your sandbox VM uses to 3 (or 4).  2 is not enough...

2. Install git:

		yum install -y git
3.  Go to your NFS loopback mount:

		cd /mapr/demo.mapr.com
		
4.  Grab the entire demos repo (for now..):

		git clone https://github.com/andypern/demos

5.	Go to the scripts directory in our specific demo folder:

		cd demos/spark-streaming-m7/scripts

6.  source env.sh:
	
		source env.sh

7. ***only works on 3.0.3 sandbox***: run dependency installer:

		sh ./get_deps.sh
>this will take several minutes or more.  It has to download > 600MB worth of dependancies, start/stop some services, and compile some Scala code into a jar file.


****Now skip down to the "Edit Variables" section.****



###Nodes that are NOT the 3.0.3 sandbox

If you really insist on running this on another type of node/cluster, you will need to spend some time getting all the pre-req's taken care of manually.  These steps are not meant to be verbose, and assume you know what you are doing.  Here's what you need:

* If using a single-node cluster, you MUST have at least 3 cpu cores.  If using a multi-node cluster, you'll need to manually launch sharkserver2 on a different node from the spark-streaming app.
* MapR 3.0.3 , with m7 license.  Other versions will require an EBF patch (available internally only)
* localhost/loopback mounts are working.
* mapr-hbase should be installed on all nodes (so that the HBASE client jars are in place)
* mapr-hivemetastore should be installed on the node you will be working on (referred to as node-1 here)
* make sure that hs2 (hiveserver2) is NOT running on node-1. EG: stop the service from MCS if need be.
* mapr-hive should be installed on all nodes (just in case) in order to get client jars
* mysql backend for hivemetastore is optional.
* install git
* install lsof
* shark + spark installed as per https://docs.google.com/a/maprtech.com/document/d/1WbyM-0RCWhCRdVrkGO5MKevWXz5U2hwWjalQGRhDHr4
* ssh keys setup so node-1 can ssh w/out password to other nodes.
* make a symlink (needed for some scala/spark/shark things):

		 ln -s /usr/bin/java /bin/java
		 


####Shark specifics

The docs for installing shark+spark are mostly complete, but since you'll be using shark with M7 you'll need to do a little extra.

1.  First, dump this into hive-site.xml (***make sure to modify hbase+hive paths to reflect proper version #'s, also make sure to put the proper zk quorum nodes in..***):


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

2. 	Make sure you are in the directory containing the shell scripts for this demo:

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


###ODBC and tableau setup

* install shark & cloudera odic drivers and plugins (links needed)
* in tableau, load up the proper ODBC connection, then choose 'multiple tables', then 'pump view' join with 'maint_table'.  save the connection  (**need screenshots**)


##Running the demo

The idea here is that you'll populate the tables once, then just re-use them over and over later.



###Intro

Show slide deck, stepping through the animations before proceeding.

* Pop into the MCS console, showing the cluster dashboard.  Highlight the 'spark-master' service running.  
* click on the 'spark master' icon in the lower-left, and then click the pop out to open a new tab, pointing to the spark-master UI.  Explain that there are 3 spark slaves running, each of which is available to share in the application load, and each of which will be leveraging CPU, RAM, and local storage for running applications and jobs.  Spark can be configured on a per application basis to utilize a specific amount of CPU and memory, and leverages data-locality in MapRFS to get the best possible performance.
* Discuss how Spark uses a Directed-Acyclic-Graph (DAG) to minimize redundant processing and maximize efficiency when running applications.
* Show that Sharkserver2 is running a an application, and explain that to spark, its just another app that can utilize resources in a coordinated and controlled manner.
* If you like, click on the shark application, then on `Application Detail UI` to show that you can even see the queries which have been run against sharkserver2, and the completion times in ms/s.


Now, lets get the data flow started.  switch to your screen w/ terminals loaded.


###Populating tables

1.  Make sure you have 3 terminal windows ssh'd into the cluster.  Put them all in the scripts folder:

		cd /mapr/demo.mapr.com/demos/spark-streaming-m7/scripts
		
2.  Then, source the env.sh file:

		source /mapr/demo.mapr.com/demos/spark-streaming-m7/scripts/env.sh
		
	>this gives you some handy aliases..
		
	

3.  In `terminal-1`, startup the listener:

		sh ./start_listener.sh
		
	or, use the alias:
	
		step-1_start_listener
	
		
	>this will kick off netcat, and drop you back into the shell


4.  Again in  `terminal-1`, launch the spark-streaming script, which will get our app running and ready to receive data: 

		sh ./run_m7_streaming_import.sh 
		
	Or, use the alias:
	
		step-2_start_streaming
	
	>After about 30 seconds the output will stop, and it will be ready to receive data.  Explain that the application is able to not only receive data as it is generated, but also insert into an M7 table, while creating a composite-key based on some of the columns, to generate a unique key which is : "PUMP_NAME_Date_Time".  Explain that the application could easily be retooled to base its composite key off of a different set of columns, or even use random numbers to spread it across regions differently.

5. Now in `terminal-2`, start pushing data.  Note that you can stop/start this at will, so long as you leave the listener and spark-streaming app running:

		sh ./push_data.sh
		
	Or, use the alias:
	
		step-3_push_data
	
	> output will show you one row every SLEEPSECS.  Notice that every BATCHSECS `terminal-1` will show some output as well..


6. Wait about 60 seconds for data to populate our table In `terminal-3` we're going to look at the table and make sure that data is appearing:

		echo "scan '/tables/sensortable', {LIMIT => 3}" | hbase shell


	Or, use the alias:
	
		step-4_table_scan
		
		


###External access to tables
		
In order for other applications (shark, and subsequently, tableau) to get access to the data inside of M7, we'll make use of external tables which are defined in the hive metastore.  All tables and views were pre-created by `create_tables.sh` previous step, so now we just want to verify that they are working.


In `terminal-3`, verify that you can run shark against this table and see data:

		shark-beeline
		
Or, use the alias:

	step-5_shark_beeline
	
		> show tables ;
		>  select * from pumpview limit 10;
>note that this query may take 10 seconds or so the first time its run, but subsequent runs will be faster.  Explain that this is a view which is joining together both our M7 external table, as well as a HIVE external table based on a CSV file containing static information about each pump (vendor name, etc)






Now that you've shown that the data is accessible via SHARK queries, its time to move on to tableau.



### Tableau



Switch to your windows desktop, and open the Tableau window.  If tableau is not launched, do so by double-clicking the 'pumps' icon on the desktop.


* Browse through sheets in tableu (pre-made).  Explain how each sheet/chart is generated by a series of SQL queries which tableau issues to mapR, and how user interactivity is dependent on fast response time to queries.

The story here is that we know that one of our pumps failed, and we want to see why. We also want to see if there are any contributing factors (vendor, maintenance schedule, or other measurements) that seem to cause failure or abnormal behavior.

* Sheets include:

	* `pump-quikview` : Shows each pump/resource-id and the sum of its flow rate (output)
	* `vendors` : Shows breakdown of each pump vendor, and their avg PSI (pressure).  2 are similar..one is significantly off.  Rolling mouse-over gives useful stats.
	* `pump pressure` : bar chart showing each pump's average PSI (pressure) rates.  One seems a bit low...
	* `pressure drop`: all pumps on a timeline, showing the peaks/valleys of the pressure and flow rates.  For the most part all pumps show even/steady pressure. Two pumps seem to drop off to the right...
	* `failure` : another timeline view, this time we look at both the PSI (upper chart) and Displacement (lower).  Mousing over displacement just prior to pressure drop seems to indicate that high displacement leads to failure..
	* `technician fail`: A filtered view, where only the two problematic pumps are displayed (you can modify the filter set if you like).  Also notice that the problematic pumps are made by the same vendor...



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


