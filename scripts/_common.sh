# common.sh

ROCKETCHAT_VERSION=0.58.4
ROCKETCHAT_SHASUM=ed53712b37571b959b5c8c8947d6335c21fced316f2b3174bfe027fa25700c44
NODE_VERSION=4.7.1

waitforservice() {
  isup=false
  seconds=90
  while [ $seconds -gt 0 ]; do
    echo "Waiting approx. $seconds seconds..."
    seconds=$(( $seconds - 1 ))
    sleep 1
    if $(curl -m 1 -s localhost:$port${path:-/}/api/v1/info |  grep -e "success.*true" >/dev/null 2>&1); then
      isup=true
      break
    fi
  done
  $isup && echo "service is up" || ynh_die "$app could not be started"
}

installdeps(){
  mongo=mongod

  if [ $(dpkg --print-architecture) == "armhf" ]; then
    # We instal this for the user and service files
    sudo apt-get update
    sudo apt-get install -y mongodb-server

    # Rocket chat requires mongodb > 2.4, which raspbian does not provide
    tarball=mongodb-linux-i686-v3.2-latest.tgz
    wget http://downloads.mongodb.org/linux/$tarball
    tar xf tarball
    sudo cp ${tarball%%.tgz}*/bin/* /usr/local/bin

    sudo sed -i -e's/bin/local\/bin/' /lib/systemd/system/mongodb.service

    mongo=mongodb
  else
    #Install mongodb for debian x86/x64
    sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 0C49F3730359A14518585931BC711F9BA15703C6
    echo "deb http://repo.mongodb.org/apt/debian jessie/mongodb-org/3.4 main" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.4.list
    sudo apt-get update
    sudo apt-get install -y mongodb-org
  fi

  # start mongodb service
  sudo systemctl enable ${mongo}.service
  sudo systemctl start ${mongo}.service

  # add mongodb to services
  sudo yunohost service add ${mongo} -l /var/log/mongodb/${mongo}.log

  #Install other dependencies
  sudo apt-get install -y gzip curl graphicsmagick npm

  # Meteor needs at least this version of node to work.
  sudo npm install -g n
  sudo n $NODE_VERSION
}
