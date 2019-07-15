#!/bin/bash



sudo apt-get update
sudo apt-get install -y git


#install infra
sudo apt-get install -y redis-server zookeeper rabbitmq-server

echo "deb http://www.apache.org/dist/cassandra/debian 311x main" | sudo tee -a /etc/apt/sources.list.d/cassandra.sources.list
curl https://www.apache.org/dist/cassandra/KEYS | sudo apt-key add -
sudo apt-get update
sudo apt-get install cassandra -y
systemctl status cassandra





git clone https://github.com/cloudwatt/nixpkgs-tungsten
cd nixpkgs-tungsten
./please init
./please install contrail50.apiServer
./please install contrail50.schemaTransformer
./please install contrail50.svcMonitor
./please install contrail50.control
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
./please install contrail50.vrouterAgent
./please install contrail50.vrouterNetNs
./please install contrail50.vrouterPortControl
./please install contrail50.vrouterUtils




mkdir /etc/contrail

#install vrouter module
#./please build contrail50.vrouterModuleUbuntu_4_4_0_119_generic


#start contrail services
/home/cloud/.nix-profile/bin/contrail-api /etc/contrail/contrail.conf &

