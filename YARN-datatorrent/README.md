#DataTorrent Demo setup



The following assumes you have a 5-node cluster, but obviously you don't need one.  Ideally you have 3 nodes, each with at least 8GB of RAM, since the DT demos tend to like to use memory. I haven't tested on a sandbox yet, but may do so and revise this document.


##Dependancies
Install a few dep's:
	
	yum clean all
	yum install -y wget
	
Grab the EPEL, this assumes you're running CENTOS-6.x

	cd /tmp
	wget http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
	rpm -Uvh epel-release-6-8.noarch.rpm

Install clush:
	
	yum install -y clustershell
	

Set this in /etc/clustershell/groups (obviously fix the hostnames...):

	yarn: yarn-demo[2-4]
	rm: yarn-demo[2]
	mr1: yarn-demo[0-1]
	all: yarn-demo[0-4]

Setup passwordless SSH , at least from node0 => other nodes.  Not covered here...

Make sure to setup the proper REPO in your /etc/yum.repos.d/maprtech.repo file.  If you want to use a temporary one you can point to my FIOS line..skip down to the appendix.


##Packages

Install core services on all nodes.  For whatever reason (hopefully fixed by the time FCS launches), I needed to do this explicitly (had to specify mapr-core up front):

	clush -a "yum install  -y mapr-fileserver  mapr-core mapr-nfs mapr-webserver mapr-hive mapr-metrics mapr-pig"



install mapr-resourcemanager on only one node : 

	clush -g rm 'yum install -y mapr-resourcemanager'


install mapr-nodemanager on  yarn nodes : 

	clush -g yarn 'yum install -y mapr-nodemanager'


install mapr-historyserver on only one node.  For now, we'll just install on the RM:

	clush -g rm 'yum install -y mapr-historyserver'
	

install mapr-tasktracker and mapr-jobtracker on only 2 nodes (one JT will be standby) : 

	clush -g mr1 'yum install -y mapr-jobtracker mapr-tasktracker'

Build your disks.txt file however you normally do.  


##Configure

Run this on YARN nodes:

	clush -g yarn "/opt/mapr/server/configure.sh -C yarn-demo0,yarn-demo2,yarn-demo4 -Z yarn-demo1,yarn-demo2,yarn-demo3 -F /tmp/disks.txt -N yarn-dt -hadoop 2 -RM yarn-demo2 -HS yarn-demo2 -M7"  
>(note the RM flag)

Run this on MR1 nodes:

	clush -g mr1 "/opt/mapr/server/configure.sh -C yarn-demo0,yarn-demo2,yarn-demo4 -Z yarn-demo1,yarn-demo2,yarn-demo3 -F /tmp/disks.txt -N yarn-dt -hadoop 1 -M7"




###Yarn-site.xml






Here's a quick workaround for https://na9.salesforce.com/500E000000AyAey?srPos=0&srKp=500 (bug 13974).  Basically go to one of your YARN nodes, and open up /opt/mapr/hadoop/hadoop-2


<!--workaround for datatorrent SFDC issue 12139 -->
		
		<property>
		    <description>CLASSPATH for YARN applications. A comma-separated list
		    of CLASSPATH entries</description>
		     <name>yarn.application.classpath</name>
		     <value>$HADOOP_CONF_DIR,$HADOOP_COMMON_HOME/share/hadoop/common/*,$HADOOP_COMMON_HOME/share/hadoop/common/lib/*,$HADOOP_HDFS_HOME/share/hadoop/hdfs/*,$HADOOP_HDFS_HOME/share/hadoop/hdfs/lib/*,$HADOOP_YARN_HOME/share/hadoop/yarn/*,$HADOOP_YARN_HOME/share/hadoop/yarn/lib/*</value>
		  </property>




clush -a -c /opt/mapr/hadoop/hadoop-2.3.0/etc/hadoop/yarn-site.xml

restart warden just to be sure.

	clush -a 'service mapr-warden restart'

	maprcli node services -name resourcemanager -action restart -nodes yarn-demo2



###make sure NFS works
These steps may not be necessary depending on your environment, but just in case:

1.  Make a /mapr dir:

		clush -a 'mkdir -p /mapr'

2.  Create a mapr_fstab file:

		echo "localhost:/mapr /mapr   hard,intr,nolock" > /opt/mapr/conf/mapr_fstab
3.  Copy around:

		clush -a -c /opt/mapr/conf/mapr_fstab

4.  Restart NFS service for good measure:

		clush -a 'service mapr-nfsserver restart'

5.  Check on all nodes after a minute to make sure its there:

		clush -a "df|grep mapr"
  



## installing datatorrent

1.  Pull down the installer:

		cd /tmp
		wget https://www.datatorrent.com/downloads/datatorrent-rts.bin
2.  Make it executable:

		chmod a+x ./datatorrent-rts*.bin
  
3.  Run it

		./datatorrent-rts*.bin
    	
	>if all went well, you should see:
   
		   DTGateway is running as pid 5021 and listening on 0.0.0.0:9090
		
		Please connect to DTGateway with a browser at http://ip-172-16-1-148:9090/ to finish remaining installation steps.  Additional documentation available from http://www.datatorrent.com/
	
	
##Configuring datatorrent


1.  Make a directory that DT can use for various things:

		mkdir -p /mapr/clustername/user/dtadmin


2.  chown it to be owned by dtadmin:

		chown dtadmin /mapr/yarn-dt/user/dtadmin

3.  Create a dtadmin user on all nodes:

		clush -a 'groupadd -g 499 dtadmin'
		clush -a 'useradd -g 499 -u 498 dtadmin'
		clush -a 'echo "dtadmin" | passwd --stdin dtadmin'

4.  Go to the DT UI (url from earlier), and start the wizard.

5.  in the UI, specify this for 'dfs location':

		/mapr/clustername/user/dtadmin/datatorrent



>While it is possible to install and manage multiple Gateway instances on different nodes, we do not recommend using them concurrently at this time.   If this is being done for high availability purposes, synchronization of configuration files located in /etc/datatorrent  will have to be executed manually at this time.


##DT demo UI

Datatorrent also has a web interface for use specifically with the bundled demos.  It leverages nodeJS.  Here's how to install (all steps performed on the DT gateway node):

	
1.  Grab the nodeJS tar ball and unpack:

		wget http://nodejs.org/dist/v0.10.28/node-v0.10.28-linux-x64.tar.gz
		tar -xzf node-v0.10.28-linux-x64.tar.gz 

2.  Go into the created directory:

		cd node-v0.10.28-linux-x64

3.  Copy the node binary somewhere in your PATH:

		cp bin/node /usr/local/bin

4.  Go to the Datatorrent demo's UI

		cd /opt/datatorrent/releases/1.0.0/demos/ui
	
5.  Modify config.js (obviously change the GATEWAY_HOST accordingly, but pay special attention to the spelling/case for the appNames):

		config.gateway.host = process.env.GATEWAY_HOST || 'yarn-demo0';
		settings.mobile.appName = 'MobileDemo';
		settings.twitter.appName = 'TwitterDemo';
		settings.fraud.appName = 'FraudDetect';
		
	
6.  You should now be able to fire up the demo UI:

		node ./app.js
	
>(may want to run inside a 'screen' session)







##Running the mobile demo:

The demo which seems to work the best, and has some interactivity, is the Mobile demo.
All steps done on the gateway node:

 

1.  make sure you are the `mapr` user

		su mapr

>note: to be able to start apps as someone other than 'mapr' =>
if you want to start application as other user. you can change
/opt/mapr/hadoop/hadoop-2.3.0/etc/hadoop/container-executor.cfg :

	min.user.id=500
	allowed.system.users=mapr

2. Launch the Datatorrent CLI:

		dtcli

3.  In the DTcli shell, run the `launch-demos` script:

		launch-demos

4.  Choose option 9

At this point you can switch to the DT UI (port 9090) as well as to the demo UI (port 3003).  


##Everything below is unfinished/untested

###Quick explanation of the mobile demo

* `phonegen`: simulates a cell tower

* `pmove` is doing computation, and updates in memory store for each location for each cell phone number.


if drops below 10,000/sec, the partitions will be reduced/squashed. if it exceeds 30k, it splits and requests more resources

physical view: shows partitions (prove has multiple)
you can increase load:

cli:

	get-operator-properties phonegen
	
returns:

	dt (application_1402347052987_0013) > get-operator-properties phonegen
	{
	  "minvalue": "5550000",
	  "tuplesBlast": "200",
	  "tuplesBlastIntervalMillis": "5",
	  "maxvalue": "5559999",
	  "name": "phonegen",
	  "class": "com.datatorrent.lib.testbench.RandomEventGenerator"
	}
	dt (

"tuplesBlast": "200", => per batch

	 set-operator-property phonegen tuplesBlast 500
	 
there is also an api to tell the system how/when to partition an operator.  they have tie-ins with kafka to adjust based on load through kafka (can write an op based on latency/cpu/etc)


go to  demo-UI 'node server' (node.js) 
you can then filter for specific phone numbers to watch them move around the map.

from the demo page, you can click lick to console and it will jump to the actual app.

In the webex recording @ about 31:00:
in the pi demo (11):

	begin-logical-plan-change 

then:

	create-operator console2 com.datatorrent.lib.io.ConsoleOutputOperator
	
now connect operator to a stream:

	add-stream-sink rand_console console2 input
rand_console => stream name (check UI for running streams)

submit the plan:

	submit

This is broken right now.
	

+++
setting up multiple gateways from an HA perspective is not yet supported.  perhaps instead you would setup multi-gw's so that different users would want different settings.  if GW fails, app continues to run (so long as yarn runs).  if the GW doesn't run, you can still use dtcli from other hosts that have it installed.

you can relaunch app from previou state in case of crash, or in case you need to load in a new jar file.


if node manager fails: it depends on timeout set for resource manager (heartbeat) .  DT also has a timeout for operators => app-master.  if that kicks in, the container gets discarded and the operator is launched there.  Timeout on DT side is 30 seconds by default.  there is checkpointing, the new operator is reset to a checkpoint.
config is in /opt/datatorrent/releases/1.0.0/conf/dt-site.xml

libs for demos:

/opt/datatorrent/releases/1.0.0/demos/lib

if building a new app, if using maven as a build tool, add a package-option to the project, put all dependancies into a folder, then move the entire folder onto the cluster.


recordings wind up on disk:


/mapr/yarn-dt/user/dtadmin/datatorrent/apps/application_1402347052987_0013/recordings/1/1402505410932


- jars for the app also wind up in the app directory in MFS (dependancies)
- jars for dt-platform go here as well
- checkpoints go here also there, are constantly rolled/changing
- keeps track of partitioning changes (when new ones come in /go/etc)
- recovery/ folder has WAL of changes, keeps track of which container is doing what.  if you shut the app down, it will use this data to recover from.  if you 'kill' an app, it uses same app-id.   if you 'stop', it gets a new app-id.  if it died in an uncontrolled manner, you would specify the  -originalAppId so it would try to re-use.  e.g.:


		launch /opt/datatorrent/current/demos/lib/malhar-demos-1.0.0.jar -originalAppId application_1402347052987_0016
it then creates a new app-id, but its re-using the state..it copies the state of original app and launches as a new one.


##appendix
ignore most of the below..unless you need it because something breaks.






###repos
Hopefully the steps below won't be necessary once FCS gets pushed to a more mainstream repo.


####Grab repo


	mkdir /repo
	cd /repo

This goes to my FIOS line @ home...don't use constantly please or my episode of GOT won't play properly.
	
	wget -r --no-clobber --no-parent http://handyhouse.no-ip.org:64080/yarn_fcs/
	rm -f index.html\?C\=*
	rm -f repodata/index.html\?C\=*



####fix repo
Need to do this because the repo has issues..not sure why. Likely this will be fixed in official FCS release.


	yum install -y createrepo
	createrepo -x mapr-compat-suse-4.0.0.25997.FCS-1.x86_64.rpm .
	chmod -R 777 /repo

To make a local mirror, we use nginx.

put this in /etc/yum.repos.d/nginx:
	
		[nginx]
		name=nginx repo
		baseurl=http://nginx.org/packages/centos/$releasever/$basearch/
		gpgcheck=0
		enabled=1

Install nginx:

	yum install -y nginx
	
setup config for this repo:
	
	vim /etc/nginx/conf.d/default.conf 
	
modify the first location:
	
		    location / {
        root   /repo;
        index  index.html index.htm;
	    }
	
Start er up:

	/etc/init.d/nginx start
	
If you're in AWS..this might make things a bit easier:

	 clush -a 'chkconfig iptables off'
	 clush -a 'service iptables stop'

	 
Make sure you can get to the repo via http.


	 
 make a maprtech repos file:
	 
	 
	 
	 vim /etc/yum.repos.d/maprtech.repo
	
	
		[maprtech]
		name=MapR Technologies
		baseurl=http://yarn-demo0/
		enabled=1
		gpgcheck=0
		protect=1
		
		[maprecosystem]
		name=MapR Technologies
		baseurl=http://package.mapr.com/releases/ecosystem/redhat/
		enabled=1
		gpgcheck=0
		protect=1
	

###disks

dumb one-liner i ran in AWS to get a disk list

	fdisk -l|grep Disk|grep GB|awk {'print $2'}|sed 's/://g' > /tmp/disks.txt

copy to all nodes:

	clush -a -c /tmp/disks.txt
	



