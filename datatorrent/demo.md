#Yarn + Datatorrent demo

##actual demo

###Intro
Show slide deck, which is something like this:

* Agenda 
* Why Yarn?
* why MapR+Yarn
* cut to demo-phase1 (CLI, config, mr1 and mr2, logs)
* Howabout a 'real' yarn app? => DT
* What is DT  and how does it differentiate (4 bullets)
* DT+Trace3+MapR @ Qualcomm: use case
* Why MapR with DT? (qualcomm needed NFS, wanted M7)
* cut to DT mobile demo
* return: where could you use this today?
* q+a

###MCS
* show dash
* highlight that some nodes have JT/TT, some have RM/NM (click each service)
* show link to RM, with high level
* show YARN vs Mapreduce panel on the right


###CLI
* show maprcli showing different services

		maprcli node list -columns hostname,svc
	also:
	
		clush -a -f 1 'ls /opt/mapr/roles' | less
		

* show /etc/clustershell/groups file

		cat /etc/clustershell/groups
		
	mention RM can only run on one node right now...
	
	

* show sample configure.sh line to configure RM and HS, make sure to show :


	MR1:
	
		 clush -g mr1 "/opt/mapr/server/configure.sh -C yarn-demo0,yarn-demo2,yarn-demo4 -Z yarn-demo1,yarn-demo2,yarn-demo3 -N yarn-dt -hadoop 1 -M7"
	MR2:
	
		 clush -g yarn "/opt/mapr/server/configure.sh -C yarn-demo0,yarn-demo2,yarn-demo4 -Z yarn-demo1,yarn-demo2,yarn-demo3 -N yarn-dt -hadoop 2 -RM yarn-demo2 -HS yarn-demo2 -M7"
		 



* show pwd on each of the two directories
* show that 'hadoop' command is symlinked differently:

		clush -g mr1 'ls -l /usr/bin/hadoop'

	and:
	
		clush -g yarn 'ls -l /usr/bin/hadoop'
		
		
		
* show class path and point out jar locations

		hadoop classpath | sed 's/:/\n/g'

* do same w/ the 0.20.2 bin (on another node)



* show a job that will fail : as root on node2:

		hadoop jar /opt/mapr/hadoop/hadoop-2.3.0/share/hadoop/mapreduce/hadoop-mapreduce-examples-2.3.0-mapr-4.0.0-FCS.jar pi 20 10000
		
* show the log file on the RM

		cd /opt/mapr/hadoop/hadoop-2.3.0/logs/
		less yarn-mapr-resourcemanager-*log

	
* on node0 : show this file: 

		vim /opt/mapr/hadoop/hadoop-2.3.0/etc/hadoop/container-executor.cfg
* modify it, clush copy and retry.

		clush -a -c /opt/mapr/hadoop/hadoop-2.3.0/etc/hadoop/container-executor.cfg	



###RM

* login directly (yarn-demo2:8088)
* Show current apps, containers, etc. click on 'nodes' link and show from there
* show metrics from MCS as well.

###Jobs

* kick off an MR1 job , show it in the JT tab or metrics (make sure these jobs will run at least 30-60 seconds)

		hadoop jar /opt/mapr/hadoop/hadoop-0.20.2/hadoop-0.20.2-dev-examples.jar wordcount /mapr/yarn-dt/wordcount /mapr/yarn-dt/output1

* while its running, kick off an MR2 job, show it in RM
On other node:
		
		cd /opt/mapr/hadoop/hadoop-2.3.0/share/hadoop/mapreduce

		hadoop jar /opt/mapr/hadoop/hadoop-2.3.0/share/hadoop/mapreduce/hadoop-mapreduce-examples-2.3.0-mapr-4.0.0-FCS.jar wordcount /mapr/yarn-dt/wordcount /mapr/yarn-dt/output2


* after job completion, show logs for NM, and app-master logs (/opt/mapr/hadoop/hadoop-2.3.0/logs/userlogs/*)

		cd /opt/mapr/hadoop/hadoop-2.3.0/logs/
		less yarn-mapr-resource*
		
		

* show how there are container specific logs as well

		
		ls
		cd userlogs
		cd *appid
		find . -ls
		
 
###DataTorrent
* if applicable, show a couple quick slides on DT
* explain how DT sits on top of YARN/hadoop
* discuss how it can request and give back resources using yarn


- Login to DT webUI : http://yarn-demo0:9090/
- explain that there's nothing going on right now..
- login to dt shell: (on node0)

		su mapr
		dtcli
		launch-demos
		
	choose 9
	
- switch back to DT UI. Show app click on it and show high level metrics
- show logical DAG
- explain that each operator is really a java class inside a jar file.
- go here: http://yarn-demo2:3003/#/ , show how it renders stuff..remove or add a ph #
- switch back to DT UI
- show physical DAG view, explaining that each instance of 'pmove' and 'phonegen' is a container
- drill down and start recording the phonegen operator.  show a view of some ph # tuples
- stop recording
- show physical view, explain that pmove  is processing the data, and that its currently occupying 'x' containers (which can also be seen in YARN). explain that each container by default will handle 10,000 => 30,000 events.  if more are needed , DT uses yarn api to ask for more. if less are needed, DT uses yarn api to give back.
- switch to CLI, modify phonegen operator to have more tuples:


		get-operator-properties phonegen
	
	set:
	
		set-operator-property phonegen tuplesBlast 800
	
	get again:
	
		get-operator-properties phonegen

- switch back to DT UI, make sure you are on the physical tab
- show how the events are ramping up, and show new 'phonegen' instances kicking off , show the container list below
- switch to physical DAG view, show that the graphic has updated to have more pmove instances/containers.
- switch to RM UI, and hit refresh.  point out the container usage and how it has gone up.
- switch back to DT cli, and scale the tuples down to 100:

			set-operator-property phonegen tuplesBlast 100
	
	get again:
	
		get-operator-properties phonegen

- switch back to DT UI, and show that the operators have been scaled back.
- switch to RM UI, and show that resources have been scaled back down.

the end.


	
	



	