RedisRaftRootFolder=/root/redisraft
BasePort=5001
N=3


function startNodes(){ # only for local testing
  for (( i = 0; i < N; i++ )); do
    port=$((BasePort + i))
    redis-server \ --port ${port} --dbfilename raft"${i}".rdb \ --loadmodule "${RedisRaftRootFolder}"/redisraft.so \ raft-log-filename raftlog"${i}".db addr localhost:"${port}" & 2>&1
    redis-cli -p ${port} raft.cluster init & 2>&1
  done
}

startNodes
redis-cli --raw -p ${BasePort} RAFT.INFO