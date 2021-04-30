Ips=(10.142.0.68 10.142.0.83)
SSHKey=/root/redisraft/setup/id_rsa
BasePort=5001

killNodes(){
 kill -9 "$(lsof -t -i:${BasePort})"
 lsof -i:"${BasePort}"
  for ip in "${Ips[@]}"
  do
    ssh -o StrictHostKeyChecking=no -i ${SSHKey} root@"$ip" "kill -9 $(lsof -t -i:${BasePort}); '$(lsof -i:${BasePort})'"
  done
}
killNodes