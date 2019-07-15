#!/bin/bash
sudo apt-get update
sudo apt-get install -y git

#install redis zookeeper rabitmq
sudo apt-get install -y redis-server zookeeper rabbitmq-server

#install cassandra
echo "deb http://www.apache.org/dist/cassandra/debian 311x main" | sudo tee -a /etc/apt/sources.list.d/cassandra.sources.list
curl https://www.apache.org/dist/cassandra/KEYS | sudo apt-key add -
sudo apt-get update
sudo apt-get install cassandra -y
#systemctl status cassandra


# 
cd
git clone https://github.com/cloudwatt/nixpkgs-tungsten
cd nixpkgs-tungsten
./please init
#contrail config 
./please install contrail50.apiServer
./please install contrail50.schemaTransformer
./please install contrail50.svcMonitor

#contrail control
./please install contrail50.control

#contrail analytics
./please install contrail50.analyticsApi
./please install contrail50.collector
nix-env -f default.nix --set-flag priority 6 contrail-control-5.0
./please install contrail50.collector
./please install contrail50.queryEngine
nix-env -f default.nix --set-flag priority 7 contrail-collector-5.0
./please install contrail50.queryEngine
./please install contrail50.vrouterAgent
nix-env --set-flag priority 8 contrail-query-engine-5.0
./please install contrail50.vrouterAgent
./please install contrail50.vrouterNetNs
./please install contrail50.vrouterPortControl
./please install contrail50.vrouterUtils

#create config files
sudo mkdir /etc/contrail
cd
sudo cp contrail-install-script/config/* /etc/contrail/.

#create log folder
sudo mkdir /var/log/contrail
sudo chmod 777 /var/log/contrail

#copy the systemd files
cd
sudo cp contrail-install-script/systemctl/* /etc/systemd/system/.

#install vrouter module
#./please build contrail50.vrouterModuleUbuntu_4_4_0_119_generic


#start contrail services
sudo systemctl start contrail-api
sudo systemctl start contrail-schema
sudo systemctl start contrail-svc-monitor
sudo systemctl start contrail-control
sudo systemctl start contrail-analytics-api
sudo systemctl start contrail-collector
sudo systemctl start contrail-query-engine


