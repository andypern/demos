#Drill demo... THIS IS NOT READY

##TODO
* lots

##Overview


##Pre-requisites



###Client/windows host



* Windows7 or 2008_server_R2 or above
* NFS client configured 
* Tableau 8.1 installed
* Drill ODBC/drill explorer? ***TBD***

###Cluster

* MapR 3.0.3 , m5 or m7 license
* localhost/loopback mounts are working.


###packages

* mapr-hbase should be installed on all nodes (so that the HBASE client jars are in place)
* mapr-hbase-master should be installed on node-1, region server on all nodes.
* mapr-hivemetastore should be installed on node-1 
* make sure that hs2 (hiveserver2) is NOT running on node-1. (either disable or put on another node)
* mapr-hive should be installed on all nodes (just in case) in order to get client jars
* mysql backend for hivemetastore is optional, but recommended.
* mapr-drill should be installed on all nodes(grab internally from yum.qa.lab/opensource)






###Startup  	
  
You should be done w/ config.  Restart drillbit on all nodes (its OK if it throws errors while stopping):

	clush -a "/opt/mapr/drill/drill-1.0.0/apache-drill-1.0.0-m2-incubating-SNAPSHOT/bin/drillbit.sh restart"
	
Wait about 30 seconds, then to verify that its running/listening:

	clush -a "lsof -i:31010"
also:

	clush -a "jps | grep Drill"



>note: drill service/etc don't show up in /opt/mapr/roles , nor in maprcli.



###Demo code prep  

1.  Install git:

		yum install -y git

2.  Go to your NFS loopback mount:

		cd /mapr/clustername
		
3.  Grab the entire demos repo (for now..):

		git clone https://github.com/andypern/demos

4.  Go to our specific demo folder:

		cd demos/drill-json-hbase-hive-tableau

5.  Make a folder where our dataset and some other related files will live:

		mkdir -p /mapr/clustername/drill_input

6.  Copy the various files we'll be using into place:

		 cp data/* /mapr/clustername/drill_input


	




##Appendix

###Shell/Query

Now run sqlline to get to a shell:

	/opt/mapr/drill/drill-1.0.0/apache-drill-1.0.0-m2-incubating-SNAPSHOT/bin/sqlline -u jdbc:drill://localhost:31012 -n admin -p admin


Query JSON file:

	select * from  dfs.`/mapr/cluster/ingest/pressure.json` limit 10;

Query HIVE table:

	select * from  hive.`tick` limit 10;
	
	
