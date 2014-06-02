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
- show a slide detailing the clickstream use case
- talk about how  data can come in different formats, and its becoming increasingly important to gain intelligence from this data without spending time developing a pre-defined schema.
- Discuss that once data is ingested onto a platform, there may be different types of consumers of this data (BI analysts doing ad-hoc query, developers writing applications, management generating long term batch-style reports), so its important to ensure that regardless of how it is stored, it can be accessed through a unified interface.



###Dataset intro
- show snippets of JSON data and CSV data (screenshot).  Highlight that JSON data is self-describing, and that drill is able to discover schema automatically without user intervention.

- Explain that this data can be ingested by several means, including using MapR's NFS interface, which allows full read/write access to the filesystem using standard tools, without client side drivers.

###Ingest example

- Show NFS in action, drag/drop a JSON file onto the cluster.

###odbc/drill explorer


- talk about ODBC (and 'drill-explorer..') and how it allows you to bring in this data into tableau, excel, and other upstream tools.

- Show the drill-explorer interface, browse through the various data sources (hive, hbase), showing a data preview for each.  Then browse for the JSON data which was most recently loaded and show how drill is able to present the data in a familiar columnar fashion.

- 



- Show a pre-created tableau report and dashboard.  Explain that it is fetching data over ODBC to drill each time an element is modified within the report.  Discuss how it is important that these queries respond in seconds (or less) in order to enable BI users to be more effective.  Mention that only drill is able to tie together not only tables with defined schema (like HIVE), but also files with self-describing schema (JSON) and key-value stores such as Apache HBASE, without applying additional schema or performing transformations (this is a stretch..since talking top HBASE requires casting)
- within the tableau report, join multiple tables (e.g.: JSON + HIVE)




###Bonus: command line queries

Show queries against:

- JSON 
- against directories full of files.
- hbase (mention it could be m7 or base..) 
- hive tables ... much faster than HIVE!  Also: show some ANSI SQL queries that cannot be done in HIVE.
- parquet files 


##Appendix

###Shell/Query

how to run sqlline to get to a shell:

	/opt/mapr/drill/drill-1.0.0/apache-drill-1.0.0-m2-incubating-SNAPSHOT/bin/sqlline -u jdbc:drill://localhost:31012 -n admin -p admin


Query JSON file:

	select * from  dfs.`/mapr/cluster/ingest/pressure.json` limit 10;

Query HIVE table:

	select * from  `hive.default`.sensor limit 10;
	
Show hive tables:

	 select * from INFORMATION_SCHEMA.`TABLES` where TABLE_SCHEMA like 'hive%';
	 



