#insert some stuff

export CLUSTER=demo.mapr.com
export MYHOST=`hostname`





export DRILL_BASEDIR=/mapr/${CLUSTER}/drill
export DRILL_DEMODIR=/mapr/${CLUSTER}/demos/drill-json-hbase-hive-tableau
export SQLLINE="/opt/mapr/drill/drill-1.0.0/apache-drill-1.0.0-m2-incubating-SNAPSHOT/bin/sqlline -u jdbc:drill://localhost:31012 -n admin -p admin"




alias demo-initialize_tables='sh ${DRILL_DEMODIR}/scripts/reset_tables.sh'
alias demo-scriptdir='cd ${DRILL_DEMODIR}/scripts && ls'
alias demo-drillbit-restart='/opt/mapr/drill/drill-1.0.0/apache-drill-1.0.0-m2-incubating-SNAPSHOT/bin/drillbit.sh restart'
alias demo-drill-connect=${SQLLINE}
alias demo-info_schema='${SQLLINE} --run=${DRILL_DEMODIR}/scripts/info_schema.sql'
alias demo-hbase-select='${SQLLINE} --run=${DRILL_DEMODIR}/scripts/hbase_select.sql'
alias demo-json-select='${SQLLINE} --run=${DRILL_DEMODIR}/scripts/json_file_select.sql'
alias demo-json-count='${SQLLINE} --run=${DRILL_DEMODIR}/scripts/json_file_count.sql'
alias demo-json-dir-select='${SQLLINE} --run=${DRILL_DEMODIR}/scripts/json_dir_select.sql'
alias demo-json-dir-count='${SQLLINE} --run=${DRILL_DEMODIR}/scripts/json_dir_count.sql'
alias demo-hive-select='${SQLLINE} --run=${DRILL_DEMODIR}/scripts/hive_select.sql'


alias demo-join-json-hive='${SQLLINE} --run=${DRILL_DEMODIR}/scripts/json_hive_join.sql'

alias demo-join-json-hbase='${SQLLINE} --run=${DRILL_DEMODIR}/scripts/json_hbase_join.sql'
