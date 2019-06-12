#!/bin/bash
echo "----------------
echo "Note your env in case of problems:
echo "VTROOT="$VTROOT
echo "VDATAROOT="$VTDATAROOT
echo "VTTOP="$VTTOP
echo "----------------"

HOSTNAME="localhost"
TOPOLOGY_FLAGS="-topo_implementation zk2 -topo_global_server_address localhost:21811,localhost:21812,localhost:21813 -topo_global_root /vitess/global"
CELL="cell1"
GRPC_PORT=15999
WEB_PORT=15000
MYSQL_AUTH_PARAM=""
BACKUP_DIR="/Users/chrisr/vtdataroot/backups"

echo "More environment set from this script:"
echo "HOSTNAME="$HOSTNAME
echo "TOPOLOGY_FLAGS="$TOPOLOGY_FLAGS
echo "CELL="$CELL
echo "GRPC_PORT="$GRPC_PORT
echo "WEB_PORT="$WEB_PORT
echo "MYSQL_AUTH_PARAM="$MYSQL_AUTH_PARAM
echo "BACKUP_DIR="$BACKUP_DIR

echo "Starting vtctld..."

echo "----------------"

mkdir -p ${BACKUP_DIR}
mkdir -p $VTDATAROOT/tmp

${VTROOT}/bin/vtctld \
  ${TOPOLOGY_FLAGS} \
  -cell ${CELL} \
  -web_dir ${VTTOP}/web/vtctld \
  -web_dir2 ${VTTOP}/web/vtctld2/app \
  -workflow_manager_init \
  -workflow_manager_use_election \
  -service_map 'grpc-vtctl' \
  -backup_storage_implementation file \
  -file_backup_storage_root ${BACKUP_DIR} \
  -log_dir ${VTDATAROOT}/tmp \
  -port ${WEB_PORT} \
  -grpc_port ${GRPC_PORT} \
  -pid_file ${VTDATAROOT}/tmp/vtctld.pid \
  ${MYSQL_AUTH_PARAM} \
  > ${VTDATAROOT}/tmp/vtctld.out 2>&1 &

echo "Access vtctld web UI at http://${HOSTNAME}:${WEB_PORT}"
echo "Send commands with: vtctlclient -server ${HOSTNAME}:${GRPC_PORT} ..."
echo "Note: vtctld writes logs under $VTDATAROOT/tmp."

echo "----------------"
echo "done."

