#!/bin/bash
echo "----------------
echo "Note your env in case of problems:
echo "VTROOT="$VTROOT
echo "VDATAROOT="$VTDATAROOT
echo "----------------"

ZK_CONFIG="1@localhost:28881:38881:21811,2@localhost:28882:38882:21812,3@localhost:28883:38883:21813"
ZK_SERVER="localhost:21811,localhost:21812,localhost:21813"
TOPOLOGY_FLAGS="-topo_implementation zk2 -topo_global_server_address localhost:21811,localhost:21812,localhost:21813 -topo_global_root /vitess/global"
CELL="cell1"

echo "More environment set from this script:"
echo "ZK_CONFIG="$ZK_CONFIG
echo "ZK_SERVER="$ZK_SERVER
echo "TOPOLOGY_FLAGS="$TOPOLOGY_FLAGS
echo "----------------"

echo "Starting zk servers..."

for i in 1 2 3
do

    ZK_ID=${i}
    ZK_DIR=zk_00${i}
    
    
    # Variables used below would be assigned values above this line
    
    mkdir -p $VTDATAROOT/tmp
    
    action='init'
    if [ -f $VTDATAROOT/$ZK_DIR/myid ]; then
        echo "Resuming from existing ZK data dir:"
        echo "    $VTDATAROOT/$ZK_DIR"
        action='start'
    fi
    
    $VTROOT/bin/zkctl -zk.myid $ZK_ID -zk.cfg $ZK_CONFIG -log_dir $VTDATAROOT/tmp $action \
    		  > $VTDATAROOT/tmp/zkctl_$ZK_ID.out 2>&1
        echo "Started zk server $ZK_ID"

    sleep 2

done

# ---
# Create /vitess/global and /vitess/CELLNAME paths if they do not exist.
echo "sleeping 5..."
sleep 5
echo "Creating /vitess/global and /vitess/CELLNAME paths if they do not exist."
zk -server ${ZK_SERVER} touch -p /vitess/global
zk -server ${ZK_SERVER} touch -p /vitess/${CELL}

# Initialize cell.
echo Initializing cell

vtctl ${TOPOLOGY_FLAGS} AddCellInfo -root /vitess/${CELL} -server_address ${ZK_SERVER} ${CELL}
zk -server ${ZK_SERVER} ls -R /

echo "----------------"
echo "And finally, the command:"
echo "    vtctl \$TOPOLOGY_FLAGS GetCellInfoNames"
echo " yields:"
vtctl $TOPOLOGY_FLAGS GetCellInfoNames
echo "----------------"
echo "done."

