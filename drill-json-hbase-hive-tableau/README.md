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


###Config

Now you'll need to modify some config files:


	vim  /opt/mapr/drill/drill-1.0.0/apache-drill-1.0.0-m2-incubating-SNAPSHOT/conf/storage-plugins.json

For this demo, we'll be using HIVE, HBASE, and local files (JSON and parquet). Make your file look similar to:
	
	{
	  "storage":{
	    dfs: {
	      type: "file",
	      connection: "maprfs:///",
	      workspaces: {
	        "root" : {
	          location: "/",
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
	    cp: {
	      type: "file",
	      connection: "classpath:///"
	    },
	    hive : {
	        type:"hive",
	        config :
	          {
	            "hive.metastore.uris" : "",
	            "javax.jdo.option.ConnectionURL" : "jdbc:derby:;databaseName=../../sample-data/drill_hive_db;create=true",
	            "hive.metastore.warehouse.dir" : "/tmp/drill_hive_wh",
	            "fs.default.name" : "maprfs:///",
	            "hive.metastore.sasl.enabled" : "false"
	          }
	      },
	    hbase : {
	      type:"hbase",
	      config : {
	        "hbase.zookeeper.quorum" : "node-1,node-2,node-3",
	        "hbase.zookeeper.property.clientPort" : 5181
	      }
	    }
	  }
	}


    
    
copy to all nodes:

	clush -a -c /opt/mapr/drill/drill-1.0.0/apache-drill-1.0.0-m2-incubating-SNAPSHOT/conf/storage-engines.json 


Add the HADOOP_HOME variable to the drill-env.sh file:

	echo "export HADOOP_HOME=/opt/mapr/hadoop/hadoop-0.20.2/" >> /opt/mapr/drill/drill-1.0.0/apache-drill-1.0.0-m2-incubating-SNAPSHOT/conf/drill-env.sh


copy to all nodes:

	clush -a -c /opt/mapr/drill/drill-1.0.0/apache-drill-1.0.0-m2-incubating-SNAPSHOT/conf/drill-env.sh
	

Modify the zookeeper config drill-override.xml to make sure that it has the right has the right zookeeper host:port pair for  (default config uses localhost:2181, many ZK installs will listen on port 5181):

	vim /opt/mapr/drill/drill-1.0.0/apache-drill-1.0.0-m2-incubating-SNAPSHOT/conf/drill-override.conf
	
	
		  zk: {
	    connect: "node-1:5181,node-2:5181,node-3:5181",
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
	
	
