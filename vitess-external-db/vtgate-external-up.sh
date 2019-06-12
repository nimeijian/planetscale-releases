#!/bin/bash

# This is an example script that starts a single vtgate.
echo "----------------
echo "Note your env in case of problems:
echo "VTROOT="$VTROOT
echo "VDATAROOT="$VTDATAROOT
echo "VTTOP="$VTTOP
echo "----------------"

HOSTNAME="localhost"
TOPOLOGY_FLAGS="-topo_implementation zk2 -topo_global_server_address localhost:21811,localhost:21812,localhost:21813 -topo_global_root /vitess/global"
CELL="cell1"
GRPC_PORT=15991
WEB_PORT=15001
MYSQL_SERVER_PORT=15306
MYSQL_AUTH_PARAM=""
BACKUP_DIR="${VTDATAROOT}/backups"

mkdir -p $VTDATAROOT/tmp
mkdir -p ${BACKUP_DIR}

#                                    {"user":      [{"Password": "xxx"}          ]}
#  -mysql_auth_server_static_string '{"mysql_user":[{"Password": "mysql_password"}]}' \
# {"mysql_user":{"Password":"mysql_password"}}

# Start vtgate.
$VTROOT/bin/vtgate \
  $TOPOLOGY_FLAGS \
  -log_dir $VTDATAROOT/tmp \
  -port ${WEB_PORT} \
  -grpc_port ${GRPC_PORT} \
  -mysql_server_port ${MYSQL_SERVER_PORT} \
  -mysql_auth_server_static_string '{"mysql_user":[{"Password": "mysql_password"}]}' \
  -cell ${CELL} \
  -cells_to_watch ${CELL} \
  -tablet_types_to_wait MASTER,REPLICA \
  -enable_buffer \
  -buffer_min_time_between_failovers=0m20s \
  -buffer_max_failover_duration=0m10s \
  -gateway_implementation discoverygateway \
  -service_map 'grpc-vtgateservice' \
  -pid_file $VTDATAROOT/tmp/vtgate.pid \
  ${MYSQL_AUTH_PARAM} \
  > $VTDATAROOT/tmp/vtgate.out 2>&1 &

echo "Access vtgate at http://${HOSTNAME}:${WEB_PORT}/debug/status"
echo Note: vtgate writes logs under $VTDATAROOT/tmp.

