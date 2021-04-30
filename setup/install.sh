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
  wait
  sudo apt-get install autoconf # install autoconf
}

function getLibSSL(){
  sudo apt-get install -y libssl-dev
}

function Main(){
  sudo apt-get update #update apt for latest package -vs
  echo "CMake Installing-----------------------------------"
  installCMake # need cmake for compiling src
  echo "CMake Installed------------------------------------"
  echo "GNUTooling Installing------------------------------"
  installGNUAutoTooling
  echo "GNUTooling Installed-------------------------------"
  echo "LibSSL Installing----------------------------------"
  getLibSSL
  echo "LibSSL Installed-----------------------------------"
  installRedis
}

Main