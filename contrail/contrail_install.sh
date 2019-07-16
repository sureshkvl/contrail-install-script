#!/bin/bash
sudo apt-get update
sudo apt-get install -y git



#install redis zookeeper rabitmq
sudo apt-get install -y redis-server zookeeperd rabbitmq-server


#creating rabbit mq users
sudo rabbitmqctl add_user stackrabbit stackqueue
sudo rabbitmqctl set_permissions -p / stackrabbit ".*" ".*" ".*"

#install cassandra
echo "deb http://www.apache.org/dist/cassandra/debian 311x main" | sudo tee -a /etc/apt/sources.list.d/cassandra.sources.list
curl https://www.apache.org/dist/cassandra/KEYS | sudo apt-key add -
sudo apt-get update
sudo apt-get install cassandra -y


# 
cd
git clone https://github.com/cloudwatt/nixpkgs-tungsten
cd nixpkgs-tungsten
./please init

#souring nix profile
. /home/cloud/.nix-profile/etc/profile.d/nix.sh
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





./please build contrail50.pythonPackages.vnc_api
sudo cp ./result/lib/python2.7/site-packages/* /usr/local/lib/python2.7/dist-packages/. -rf

./please build contrail50.pythonPackages.cfgm_common
sudo cp ./result/lib/python2.7/site-packages/* /usr/local/lib/python2.7/dist-packages/. -rf

./please build contrail50.pythonPackages.contrail_vrouter_api
sudo cp ./result/lib/python2.7/site-packages/* /usr/local/lib/python2.7/dist-packages/. -rf

./please build contrail50.pythonPackages.vnc_openstack
sudo cp ./result/lib/python2.7/site-packages/* /usr/local/lib/python2.7/dist-packages/. -rf


#install contraill api cli
./please install contrailApiCliWithExtra

# provisioning scripts
./please install contrail50.configUtils


#create config files
sudo mkdir /etc/contrail
cd
sudo cp contrail-install-script/contrail/config/* /etc/contrail/.

#create log folder
sudo mkdir /var/log/contrail
sudo chmod 777 /var/log/contrail

#copy the systemd files
cd
sudo cp contrail-install-script/contrail/systemctl/* /etc/systemd/system/.

# reload he systemctl
sudo systemctl daemon-reload

#start contrail services
#sudo systemctl start contrail@api
#sudo systemctl start contrail@schema
#sudo systemctl start contrail@svc-monitor
#sudo systemctl start contrail@control
#sudo systemctl start contrail@analytics-api
#sudo systemctl start contrail@collector
#sudo systemctl start contrail@query-engine


