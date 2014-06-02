#insert some stuff

export CLUSTER=demo.mapr.com
export MYHOST=`hostname`





export DRILL_BASEDIR=/mapr/${CLUSTER}/drill
export DRILL_DEMODIR=/mapr/${CLUSTER}/demos/drill-json-hbase-hive-tableau




alias drilldemo-drillbit-restart='/opt/mapr/drill/drill-1.0.0/apache-drill-1.0.0-m2-incubating-SNAPSHOT/bin/drillbit.sh restart'

alias drilldemo-drill-connect='/opt/mapr/drill/drill-1.0.0/apache-drill-1.0.0-m2-incubating-SNAPSHOT/bin/sqlline -u jdbc:drill://localhost:31012 -n admin -p admin'

alias drilldemo-initialize_tables='sh ${DRILL_DEMODIR}/scripts/reset_tables.sh'