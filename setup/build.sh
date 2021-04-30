RedisRaftRootFolder=/root/redisraft
cd "${RedisRaftRootFolder}" #if you arent there already...
git submodule init
git submodule update
make -B