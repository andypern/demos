#Shark, Spark, M7


##TODO

some nice to haves:

* snapshot integration
* mirror integration
* leverage spark to perform ingest and/or transformation
* 

##Overview

The goal of this demo is to show users how to use MapR, in conjunction with spark, shark, and MapR-tables (M7) to :

* ingest data using network transport (socket)
*  spark-streaming to load data into m7-table
*  
* Use shark to query data , both from M7, as well as from flat files (csv)
* Leverage ODBC drivers to allow Tableau to access data in M7



## Pre-requisites

###cluster
* MapR 3.0.3 , with m7 license
* shark + spark installed as per https://docs.google.com/a/maprtech.com/document/d/1WbyM-0RCWhCRdVrkGO5MKevWXz5U2hwWjalQGRhDHr4


and dump this into hive-site.xml:


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
  
 then:
 clush -a -c /opt/mapr/hive/hive-0.12/conf/hive-site.xml
 
  and shove this into /opt/mapr/shark/shark-0.90/run (on line 63):
  
  SPARK_CLASSPATH+=:/opt/mapr/hive/hive-0.12/lib/hive-exec-0.12-mapr-1403.jar
  

* yum install -y git
* cd /mapr/clustername
* git clone https://github.com/andypern/demos
* cd demos/spark-streaming-m7
* mkdir -p /mapr/clustername/ingest
* cp data/* /mapr/clustername/ingest
* cd m7_streaming_import
* sbt/sbt package  (this might take a few minutes)
* in a separate SSH session:
* 	cd /mapr/clustername/demos/spark-streaming-m7/scripts
* 	sh ./launch_datastream.sh
* Then in your other (free) session, run : sh run_m7_streaming_import.sh 
* after awhile..crtl-c on both windows to kill it.

run 'hbase shell' and scan to make sure stuff shows up:

scan '/tables/sensortable'

now create hive external table:

hive -f scripts/create_ext_table.hql

do a 'hive -e "select * from sensor limit 10;"' to make sure it works

now try shark:

/opt/mapr/shark/shark-0.9.0/bin/shark







###Client/windows host

* Windows7 or 2008_server_R2 or above
* NFS client configured 
* Tableau 8.1 installed
* MapR ODBC drivers installed (***need link***)



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

* thrift API for python to get access to M7 tables
* do i need to use tachyon?

***I AM HERE***



###load data into table (importtsv)

(***3 mins***)

1.  Switch to a CLI.  Explain that we will be loading the data into our newly created table using a simple script.  Run script: 

		sh /mapr/mycluster/scripts/import_sensor.sh vol1 sensor

2.  Show via MCS UI the 'regions' tab for this table to show size, # of rows, etc. 

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


