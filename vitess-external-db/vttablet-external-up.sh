#!/bin/bash
export VDATAROOT=${HOME}/vtdataroot
echo "----------------
echo "Note your env in case of problems:
echo "VTROOT="$VTROOT
echo "VDATAROOT="$HOME/vtdataroot

echo "VTTOP="$VTTOP
echo "----------------"

export VT_MYSQL_ROOT=/usr/local/opt/mysql@5.6
export MYSQL_FLAVOR=MySQL56

export mysql_user=ext_user
export mysql_pass=ext_password

MYSQL_AUTH_PARAM=""

DBNAME=commerce
KEYSPACE=commerce
TOPOLOGY_FLAGS="-topo_implementation zk2 -topo_global_server_address localhost:21811,localhost:21812,localhost:21813 -topo_global_root /vitess/global"
DBCONFIG_DBA_FLAGS="-db-config-dba-uname $mysql_user -db-config-dba-pass $mysql_pass -db-config-dba-charset utf8"
DBCONFIG_FLAGS="-db-config-dba-uname $mysql_user -db-config-dba-pass $mysql_pass -db-config-dba-charset utf8 -db-config-dba-host localhost -db-config-dba-port 3306 -db-config-allprivs-uname $mysql_user -db-config-allprivs-pass $mysql_pass -db-config-allprivs-charset utf8 -db-config-allprivs-host localhost -db-config-allprivs-port 3306 -db-config-app-uname $mysql_user -db-config-app-pass $mysql_pass -db-config-app-charset utf8 -db-config-app-host localhost -db-config-app-port 3306 -db-config-repl-uname $mysql_user -db-config-repl-pass $mysql_pass -db-config-repl-charset utf8 -db-config-repl-host localhost -db-config-repl-port 3306 -db-config-filtered-uname $mysql_user -db-config-filtered-pass $mysql_pass -db-config-filtered-charset utf8 -db-config-filtered-host localhost -db-config-filtered-port 3306 -db_host localhost -db_port 3306"
INIT_DB_SQL_FILE=init_db.sql
VTCTLD_HOST=localhost
VTCTLD_WEB_PORT=15000
HOSTNAME=localhost

TABLET_DIR=vt_0000000100
UNIQUE_ID=100
MYSQL_PORT=3306
WEB_PORT=15201
GRPC_PORT=16201
ALIAS=cell1-0000000100
SHARD=0
TABLET_TYPE=replica
EXTRA_PARAMS="-mycnf_server_id 100"
EXTERNAL_MYSQL=1
BACKUP_DIR="$VTDATAROOT/backups"

# Variables used below would be assigned values above this line
BACKUP_PARAMS_S3="-backup_storage_implementation s3 -s3_backup_aws_region us-west-2 -s3_backup_storage_bucket vtlabs-vtbackup"
if [ $EXTERNAL_MYSQL -eq 0 ]; then
    BACKUP_PARAMS_FILE="-backup_storage_implementation file -file_backup_storage_root ${BACKUP_DIR} -restore_from_backup"
else
    BACKUP_PARAMS_FILE=""
fi

BACKUP_PARAMS=${BACKUP_PARAMS_FILE}

export LD_LIBRARY_PATH=${VTROOT}/dist/grpc/usr/local/lib
export PATH=${VTROOT}/bin:${VTROOT}/.local/bin:${VTROOT}/dist/chromedriver:${VTROOT}/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin:/usr/local/go/bin:/usr/local/mysql/bin

ORC_HOST=${VTCTLD_HOST}
ORC_PORT=30000

case "$MYSQL_FLAVOR" in
  "MySQL56")
    export EXTRA_MY_CNF=$VTROOT/config/mycnf/master_mysql56.cnf
    ;;
  "MariaDB")
    export EXTRA_MY_CNF=$VTROOT/config/mycnf/master_mariadb.cnf
    ;;
  *)
    echo "Please set MYSQL_FLAVOR to MySQL56 or MariaDB."
    exit 1
    ;;
esac


mkdir -p ${VTDATAROOT}/vt_0000000100
mkdir -p ${VTDATAROOT}/tmp
mkdir -p ${BACKUP_DIR}


echo "Starting vttablet for $ALIAS..."

$VTROOT/bin/vttablet \
    $TOPOLOGY_FLAGS \
    -log_dir $VTDATAROOT/tmp \
    -tablet-path $ALIAS \
    -tablet_hostname "$HOSTNAME" \
    -init_keyspace $KEYSPACE \
    -init_shard $SHARD \
    -init_tablet_type $TABLET_TYPE \
    -init_db_name_override $DBNAME \
    -mycnf_mysql_port $MYSQL_PORT \
    -health_check_interval 5s \
    $BACKUP_PARAMS \
    -binlog_use_v3_resharding_mode \
    -port $WEB_PORT \
    -grpc_port $GRPC_PORT \
    -service_map 'grpc-queryservice,grpc-tabletmanager,grpc-updatestream' \
    -pid_file $VTDATAROOT/$TABLET_DIR/vttablet.pid \
    -vtctld_addr http://${VTCTLD_HOST}:${VTCTLD_WEB_PORT}/ \
    -orc_api_url http://${ORC_HOST}:${ORC_PORT}/api \
    -orc_discover_interval "2m" \
    $DBCONFIG_FLAGS \
    ${MYSQL_AUTH_PARAM} ${EXTRA_PARAMS}\
    > $VTDATAROOT/$TABLET_DIR/vttablet.out 2>&1 &

echo "Access tablet $ALIAS at http://$HOSTNAME:$WEB_PORT/debug/status"

