#Shark, Spark, M7
This is a work in progress...

##TODO

* add some screenshots to this doc
* simplify the procedure (put more logic into the shell scripts)
* Add visualization for realtime (e.g.: dispatch to D3/etc prior to insertion into M7)

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
* MapR ODBC drivers installed (***need link***)


###cluster
* MapR 3.0.3 , with m7 license
* localhost/loopback mounts are working.
* shark + spark installed as per https://docs.google.com/a/maprtech.com/document/d/1WbyM-0RCWhCRdVrkGO5MKevWXz5U2hwWjalQGRhDHr4
* Make sure you can get to the spark UI (on port 8080), and that you can fire off slaves/workers successfully.
* Also take note of the spark URL (spark://hostname:7077) EXACTLY, as you'll need it later.


####Shark specifics

The docs for installing shark+spark are mostly complete, but if you want to use shark with M7 you'll need to do a little extra.

1.  First, dump this into hive-site.xml (***make sure to modify hbase+hive paths to reflect proper version #'s, also make sure to put the proper zk quorum nodes in..***):


		<!--this is to get shark to work w/ m7-->
		<property>
		<name>hive.aux.jars.path</name>
		   <value>file:///opt/mapr/hive/hive-0.12/lib/hive-hbase-handler-0.12-mapr-1403.jar,file:///opt/mapr/hbase/hbase-0.94.13/hbase-0.94.13-mapr-1403.jar,file:///opt/mapr/zookeeper/zookeeper-3.3.6/zookeeper-3.3.6.jar</value>
		   <description>A comma separated list (with no spaces) of the jar files required for Hive-HBase integration</description>
		 </property>
		
		<property>
		  <name>hbase.zookeeper.quorum</name>
		  <value>node-1,node-2,node-3</value>
		  <description>A comma separated list (with no spaces) of the IP addresses of all ZooKeeper servers in the cluster.</description>
		</property>
		
		 <property>
		  <name>hbase.zookeeper.property.clientPort</name>
		  <value>5181</value>
		  <description>The Zookeeper client port. The MapR default clientPort is 5181.</description>
		 </property>
  
 
 
 2.  Copy that to all nodes for good measure:
 
		 clush -a -c /opt/mapr/hive/hive-0.12/conf/hive-site.xml
 
 3.  We have to trick the shark 'run' parameters a little, and insert a hive jar into the class path manually. 

		vim /opt/mapr/shark/shark-0.90/run 
	>edit line 63, but make sure you load this AFTER the lib_managed jars get loaded:
  
		  SPARK_CLASSPATH+=:/opt/mapr/hive/hive-0.12/lib/hive-exec-0.12-mapr-1403.jar
  
###Demo code prep  

1.  Install git:

		yum install -y git

2.  Go to your NFS loopback mount:

		cd /mapr/clustername
		
3.  Grab the entire demos repo (for now..):

		git clone https://github.com/andypern/demos

4.  Go to our specific demo folder:

		cd demos/spark-streaming-m7

5.  Make a folder where our dataset and some other related files will live:

		mkdir -p /mapr/clustername/ingest

6.  Copy the various CSV files we'll be using into place:

		 cp data/* /mapr/clustername/ingest

7. Change directories to where our SCALA code lives:

		 cd m7_streaming_import

8.  Use SBT to package the JAR:

		sbt/sbt package  
	>(this might take a few minutes)


###Edit variables


1.  Open a new SSH session to the node you've been working on

2. 	Go into the directory containing the shell scripts for this demo:

		cd /mapr/clustername/demos/spark-streaming-m7/scripts

3.	Modify the launch_datastream.sh script.  You will want to change some of the following variables (esp the CLUSTER).  The SLEEPSECS variable tells the script how long to wait between sending lines to the network socket.  .25 seconds means that 4 lines/second will be sent.

		CLUSTER=summit2014
		BASEDIR=/mapr/${CLUSTER}/ingest
		SOURCE_FILE=${BASEDIR}/SensorDataV5.csv
		PORT=9999
		SLEEPSECS=.25


4.  Modify the run_m7_streaming_import.sh script.  Make sure to change the CLUSTER, SPARK_URL (must match exactly what you see in the spark UI), MYHOST (should be the node you are working on).  You don't need to change the TABLENAME or OUTFILE/JARFILE, the script will create paths automatically.

		CLUSTER=summit2014
		SPARK_URL=spark://ip-10-170-142-235.us-west-1.compute.internal:7077
		MYHOST=ip-10-170-142-235
		PORT=9999 
		BATCHSECS=3 
		TABLENAME=/tables/sensortable 
		OUTFILE=/mapr/${CLUSTER}/CSV/sensor.csv
		JARFILE=/mapr/${CLUSTER}/demos/spark-streaming-m7/m7_streaming_import/target/scala-2.10/m7import_2.10-0.1-SNAPSHOT.jar





##Running things..

###Populating tables

1.  Make sure you have 3 terminal windows ssh'd into the cluster, where you've cd'd into the following directory:

		/mapr/clustername/demos/spark-streaming-m7/scripts

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
		
In order for other applications (shark, and subsequently, tableau) to get access to the data inside of M7, we'll need to create some external tables.

All work here is done in 'terminal-3'

1.  First, create a table which points to our M7 data:

		hive -f create_ext_table.hql
>this should return quickly

2.  Verify that you can run shark against this table and see data:

		/opt/mapr/shark/shark-0.9.0/bin/shark -e "select * from sensor limit 10;"





##Everything below doesn't work







##Demo procedure

###Introduce MCS

1. Show tables section of MCS (***2 mins***)
	* show tables: 2 will exist.  One will be large enough to be auto split into regions.
	* talk about column families, and browse column Family options with the UI.


2.  Switch to Volumes section of MCS.  Explain/show that tables live within volumes, and that volumes can be setup to be mirrored, snapshotted, etc. (***2 mins***)

3.  Show a pre-existing snapshot schedule on the volume, explain how it provides a layer of protection against user deletions or rogue applications.  (***2 mins***)
	
	

3. Use CLI to create a new volume and a table (***1 min***)

from CLI:

	 sh /mapr/mycluster/scripts/create_vol_table.sh vol1 sensor
	 
	
	
4. go back to MCS UI:  (***1 min***)
	* show new volume
	* show table 
	* explain that the table is empty right now

5.  Show dataset: (***2 mins***)

	* Browse to dataset on local HD.	
	* Show snip of sample dataset via text editor.  Briefly explain the columns which will be used.
	
	

###ingest data over NFS

(***3 mins***)


* copy both CSV files from the desktop using windows explorer browser, put it into the input directory (/mapr/mycluster/input).  Explain how the NFS read-write filesystem is Unique to MapR, and makes ingestion of data from various sources much easier. 

###process/sanitize data w/ spark?

Need to develop some story here..perhaps we want to create aggregations in spark that are output or inserted into M7?  as opposed to using importtsv?
Some ideas:






3.  Run a quick 'scan' from CLI to show one row: 

		hbase shell
		scan '/mapr/mycluster/tables/vol1/sensor', {LIMIT => 1}
	


###Create  HIVE tables

(***5 mins***)

1.  Switch to CLI, show the create_ext_table.hql hive-script.  Explain that this table merely points to our newly created table, in order to enable SQL access into the data.
	


2.  run the hive script to create the table:
	
		hive -f /mapr/mycluster/scripts/create_ext_table.hql 
		
3.  Show new table and one row:

		hive -e "show tables;"
	

	
		hive -e "select * from sensor limit 10;"

4.  create the pump_info table, which contains information about the pumps such as vendor, location, etc.

		hive -f /mapr/mycluster/scripts/create_pump_table.hql


> if need be, verify w/ shark that these tables show up and are query-able.



### Tableau

(***5-10 mins***)

Switch back to the windows desktop, and open the Tableau window.

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


