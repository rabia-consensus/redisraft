RedisRaftRootFolder=/root/redisraft
BasePort=5001
N=3


function startNodes(){ # only for local testing
  for (( i = 0; i < N; i++ )); do
    port=$((BasePort + i))
    redis-server \ --port ${port} --dbfilename raft"${i}".rdb \ --loadmodule "${RedisRaftRootFolder}"/redisraft.so \ raft-log-filename raftlog"${i}".db addr localhost:"${port}" & 2>&1
    if [ "$i" -eq 0 ]; then
      redis-cli -p ${port} raft.cluster init & 2>&1
    else
      redis-cli -p ${port} RAFT.CLUSTER JOIN localhost:"${BasePort}" & 2>&1
    fi
  done
  redis-cli --raw -p ${BasePort} RAFT.INFO
}
startNodes