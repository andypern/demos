#Drill demo... THIS IS NOT READY

##TODO
* lots

##Overview


##Pre-requisites



###Client/windows host



* Windows7 or 2008_server_R2 or above
* NFS client configured 
* Tableau 8.1 installed
* Drill ODBC/drill explorer
* copy TDC file into the Tableau datasources folder (**need detail**)

###Cluster

* MapR 3.0.3 , m5 or m7 license
* localhost/loopback mounts are working.


###packages

* mapr-hbase should be installed on all nodes (so that the HBASE client jars are in place)
* mapr-hbase-master should be installed on node-1, mapr-hbase-regionserver on all nodes.
* mapr-hivemetastore should be installed on node-1 
* mapr-hive should be installed on all nodes (just in case) in order to get client jars
* mysql backend for hivemetastore is optional, but recommended.
* mapr-drill should be installed on all nodes(grab internally from yum.qa.lab/opensource)
* run configure.sh -R on all nodes to make sure all roles are picked up.

###Config

***need to modify memory limits for drill***

Now you'll need to modify some config files:



Add the HADOOP_HOME variable to the drill-env.sh file:

	echo "export HADOOP_HOME=/opt/mapr/hadoop/hadoop-0.20.2/" >> /opt/mapr/drill/drill-1.0.0/apache-drill-1.0.0-m2-incubating-SNAPSHOT/conf/drill-env.sh
	
	
copy to all nodes:

	clush -a -c /opt/mapr/drill/drill-1.0.0/apache-drill-1.0.0-m2-incubating-SNAPSHOT/conf/drill-env.sh
	
	

**Note, all of the following assume you are using the 3.0.3 sandbox.  If you are using another cluster/version, pay special attention to the URI's,hostnames and cluster name (look for `maprdemo` and `demo.mapr.com` and replace where necessary)**


	vim  /opt/mapr/drill/drill-1.0.0/apache-drill-1.0.0-m2-incubating-SNAPSHOT/conf/storage-plugins.json

For this demo, we'll be using HIVE, HBASE, and local files (JSON and parquet). Make your file look similar to:
	
	{
	  "storage":{
	    dfs: {
	      type: "file",
	      connection: "maprfs:///",
	      workspaces: {
	        "MFS root" : {
	          location: "/mapr/demo.mapr.com",
	          writable: false
	        },
	        "tmp" : {
	          location: "/tmp",
	          writable: true,
	          storageformat: "csv"
	        }
	      },
	      formats: {
	        "psv" : {
	          type: "text",
	          extensions: [ "tbl" ],
	          delimiter: "|"
	        },
	        "csv" : {
	          type: "text",
	          extensions: [ "csv" ],
	          delimiter: ","
	        },
	        "parquet" : {
	          type: "parquet"
	        },
	        "json" : {
	          type: "json"
	        }
	      }
	    },
	    
	    hive : {
	        type:"hive",
	        config :
	          {
	            "hive.metastore.uris" : "thrift://maprdemo:9083",
	            "hive.metastore.sasl.enabled" : "false"
	          }
	      },
	      M7 : {
      type:"hbase",
      config : {
         "hbase.zookeeper.quorum": "maprdemo",
         "hbase.zookeeper.property.clientPort": 5181,
         "hbase.table.namespace.mappings": "*:/tables"
         }
      },
	    hbase : {
	      type:"hbase",
	      config : {
	        "hbase.zookeeper.quorum" : "maprdemo",
	        "hbase.zookeeper.property.clientPort" : 5181
	      }
	    }
	  }
	}


    
    
copy to all nodes:

	clush -a -c /opt/mapr/drill/drill-1.0.0/apache-drill-1.0.0-m2-incubating-SNAPSHOT/conf/storage-engines.json 





Modify the zookeeper config drill-override.xml to make sure that it has the right has the right zookeeper host:port pair for  (default config uses localhost:2181, many ZK installs will listen on port 5181):

	vim /opt/mapr/drill/drill-1.0.0/apache-drill-1.0.0-m2-incubating-SNAPSHOT/conf/drill-override.conf
	
	
		  zk: {
	    connect: "maprdemo:5181",
	    root: "/drill",
	    refresh: 500,
	    timeout: 5000,
	    retry: {
	      count: 7200,
	      delay: 500
	    }
	},
        
copy to all nodes:
  

	clush -a -c /opt/mapr/drill/drill-1.0.0/apache-drill-1.0.0-m2-incubating-SNAPSHOT/conf/drill-override.conf 
  	







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

		cd /mapr/demo.mapr.com
		
3.  Grab the entire demos repo (for now..):

		git clone https://github.com/andypern/demos

4.  Go to our specific demo folder:

		cd demos/drill-json-hbase-hive-tableau

5.  Make a folder where our dataset and some other related files will live:

		mkdir -p /mapr/demo.mapr.com/drill_input

6.  Copy the various files we'll be using into place:

		 cp data/* /mapr/demo.mapr.com/drill_input

7.  Mount up your cluster via NFS to your desktop, then copy the `drill_input` folder to your desktop so it can be ingested later.

	
##Running the demo

###Introduction

- Show a slide with a diagram showing the components
- talk about how  data can come in different formats, and its becoming increasingly important to gain intelligence from this data without spending time developing a pre-defined schema.
- Discuss that once data is ingested onto a platform, there may be different types of consumers of this data (BI analysts doing ad-hoc query, developers writing applications, management generating long term batch-style reports), so its important to ensure that regardless of how it is stored, it can be accessed through a unified interface.



###Dataset intro
- show snippets of JSON data and CSV data (screenshot).  Highlight that JSON data is self-describing, and that drill is able to discover schema automatically without user intervention.

- Explain that this data can be ingested by several means, including using MapR's NFS interface, which allows full read/write access to the filesystem using standard tools, without client side drivers.

###Ingest example

Show NFS in action, drag/drop some files onto the cluster:

1.  On your windows desktop there should be a 'drill-data' folder.  Inside are some JSON files.
2.  right-click/copy, then navigate to the "N:" drive, which is an NFS mount to the cluster (if the NFS mount isn't working, browse to \\hostname\mapr\clustername)
3.  Go into the drill folder, then the JSON folder.  If there are existing files in there delete them, and copy your files in from your desktop






##odbc/drill explorer


 talk about ODBC (and 'drill-explorer..') and how it allows you to bring in this data into tableau, excel, and other upstream tools.




 Show the drill-explorer interface, browse through the various data sources :

	
1.  double click the `drill-odbc` icon on the desktop

2.  Click the `System DSN` tab

3.  Make sure `drill-demo` is highlighted, then click `Configure`

4.  Click the `Test` button, and make sure it completes successfully

5.  Click the `Drill Explorer` button to launch drill-explorer.


Once inside drill explorer, you can navigate and preview some of your data sources.  Note that because drill is still pre-beta, some data sources aren't going to preview properly.

1.  Expand `hive.default`, and click on the `clicks` table.  You should see a preview of the schema and the data.

2.  Expand `hbase`, and expand the `hbusers` table.  It should show you a list of column families.  Note that currently drill explorer isn't able to properly see inside the CF's, that's coming soon.

	> bonus, if you want to get tricky, you can preview the data in the HBASE table properly:
	
	* Click the `SQL` tab at the top of the screen
	*  paste the following in (exactly):
	
			select cast(account['id'] as VarChar(20)) as id,
			cast(account['name'] as VarChar(20)) as name,
			cast(metrics['gender'] as VarChar(20)) as gender,
			cast(address['address'] as VarChar(20)) as address,
			cast(metrics['first_visit'] as VarChar(20)) as first_visit 
			from `hbase`.`hbusers` limit 10
			
	* click the `Preview` button
	* note that the `Save As` button doesn't work yet, but soon it will allow you to save custom views

3.  Expand `dfs.default` , and browse to `drill`, then `JSON`.  If you have the `JSON` folder highlighted, you see a preview of *all* data within that directory.  If you expand the folder, and click on one of the files, you'll see a preview from just one of those files.

 

Showing a data preview for each.



Talk about how ODBC support for Tableau is coming soon!





###Bonus: command line queries

All of the queries are located at /mapr/clustername/demos/drill-json-hbase-hive-tableau/scripts .  You can just use the following alias to get there though:

		demo-scriptdir
	
It might be useful to show viewers some of the queries you'll be running.  To save on typing...use the aliases:


To launch the SQL-line shell, run the following alias:

	demo-drill-connect

1.  To list out tables via INFORMATION SCHEMA:
	
		demo-info_schema


2. To query a JSON file :

		demo-json-select
		
	Now do a count(*) to show the row count:
	
		demo-json-count
		
3.  Howabout a whole directory full of JSON:

		demo-json-dir-select
	Now do a count(*) to show a _larger_ row count:
	
		demo-json-dir-count
		
		
4.  Query hbase (mention it could be m7 or Hbase..).  Note that there are some specific 'casts' required, check the `hbase_select.sql` file.

		demo-hbase-select



5. Query HIVE tables (no map reduce required!)  :

		demo-hive-select
		
		
***Note: joins are problematic right now...***





##Appendix

