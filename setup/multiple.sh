RedisRaftRootFolder=/root/redisraft
SSHKey=/root/redisraft/setup/id_rsa
BasePort=5001
N=3
Ips=(10.142.0.59 10.142.0.59 10.142.0.68 10.142.0.83)
BaseIp=10.142.0.59

startNodes(){
  i=0
  for ip in "${Ips[@]}"
  do
      if [ $i -eq 0 ]; then
        redis-server \ --port ${BasePort} --dbfilename raft"${i}".rdb \ --loadmodule "${RedisRaftRootFolder}"/redisraft.so \ raft-log-filename raftlog"${i}".db addr localhost:"${BasePort}" & 2>&1
        redis-cli -p ${BasePort} raft.cluster init & 2>&1
        sleep 0.3
      else
        ssh -o StrictHostKeyChecking=no -i ${SSHKey} root@"$ip" "redis-server \ --port ${BasePort} --dbfilename raft'${i}'.rdb \ --loadmodule "${RedisRaftRootFolder}"/redisraft.so \ raft-log-filename raftlog'${i}'.db addr localhost:'${BasePort}' & 2>&1; redis-cli -p ${BasePort} RAFT.CLUSTER JOIN '${BaseIp}':'${BasePort}' & 2>&1"
        sleep 0.3
      fi
      ((i++))
  done
  redis-cli --raw -p 5001 RAFT.INFO
}