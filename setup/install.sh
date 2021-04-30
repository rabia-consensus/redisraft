# This script is intended for downloading and setting up Redis and C compilation on Ubuntu
# This also assumes adequate version of C installed already
RedisRaftRootFolder=root/redisraft

function installCMake(){
  sudo apt-get install build-essential libssl-dev
  wait
  cd /tmp
  wget https://github.com/Kitware/CMake/releases/download/v3.20.0/cmake-3.20.0.tar.gz
  wait
  tar -zxvf cmake-3.20.0.tar.gz
  wait
  cd cmake-3.20.0
  ./bootstrap
  wait
  make
  sudo make install
  wait
  cmake --version
}

function installRedis(){
  sudo add-apt-repository ppa:redislabs/redis
  sudo apt-get install redis
  sudo apt install redis-server
  sudo systemctl status redis
}

function installGNUAutoTooling(){
  sudo apt-get install autotools-dev # install autotooling
  sudo apt-get install autoconf # install autoconf
  apt-get install -y libtool # install libtool
}

function getLibSSL(){
  sudo apt-get install -y libssl-dev
}

function Main(){
  sudo apt-get update #update apt for latest package -vs
  installCMake # need cmake for compiling src
  installGNUAutoTooling
  getLibSSL
  installRedis
}

Main