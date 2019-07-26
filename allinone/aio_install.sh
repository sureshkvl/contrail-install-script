#!/bin/bash

HOMEDIR=/home/cloud
HOSTIP=10.1.1.1


function setup_infra_services() {

	sudo apt-get update
	sudo apt-get install -y git
	#install redis zookeeper rabitmq
	sudo apt-get install -y redis-server zookeeperd rabbitmq-server

	#install cassandra
	echo "deb http://www.apache.org/dist/cassandra/debian 311x main" | sudo tee -a /etc/apt/sources.list.d/cassandra.sources.list
	curl https://www.apache.org/dist/cassandra/KEYS | sudo apt-key add -
	sudo apt-get update
	sudo apt-get install cassandra -y
}


function configure_cassandra() {
	sudo sed -i 's/start_rpc: false/start_rpc: true/' /etc/cassandra/cassandra.yaml
	sudo service cassandra restart
}

function configure_redis() {

	sudo sed -i 's/bind localhost/bind 0.0.0.0/' /etc/redis/redis.conf
	sudo service redis-server restart
}

function configure_rabbitmq() {
	#creating rabbit mq users
	sudo rabbitmqctl add_user contrail contrail
	sudo rabbitmqctl set_permissions -p / contrail ".*" ".*" ".*"
}


function install_contrail(){

	cd $HOMEDIR
	git clone https://github.com/cloudwatt/nixpkgs-tungsten
	cd nixpkgs-tungsten
	./please init

	#souring nix profile
	. $HOMEDIR/.nix-profile/etc/profile.d/nix.sh
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
	nix-env -f default.nix --set-flag priority 8 contrail-query-engine-5.0


	#install the vrouter agent
	./please install contrail50.vrouterAgent
	./please install contrail50.vrouterNetNs
	./please install contrail50.vrouterPortControl
	./please install contrail50.vrouterUtils
	# provision scripts are available in configutils package
	./please install contrail50.configUtils
	#install contraill api cli
	./please install contrailApiCliWithExtra



	#install python packages and move it in to python lib folder

	./please build contrail50.pythonPackages.vnc_api
	sudo cp ./result/lib/python2.7/site-packages/* /usr/local/lib/python2.7/dist-packages/. -rf

	./please build contrail50.pythonPackages.cfgm_common
	sudo cp ./result/lib/python2.7/site-packages/* /usr/local/lib/python2.7/dist-packages/. -rf

	./please build contrail50.pythonPackages.contrail_vrouter_api
	sudo cp ./result/lib/python2.7/site-packages/* /usr/local/lib/python2.7/dist-packages/. -rf

	./please build contrail50.pythonPackages.vnc_openstack
	sudo cp ./result/lib/python2.7/site-packages/* /usr/local/lib/python2.7/dist-packages/. -rf

	./please build contrail50.pythonPackages.contrail_neutron_plugin
	sudo cp ./result/lib/python2.7/site-packages/* /usr/local/lib/python2.7/dist-packages/. -rf
}


function copy_config(){
	#create config file folder

	if [ ! -d "/etc/contrail" ];
	then
		sudo mkdir /etc/contrail
	fi

	#create log folder
	if [ ! -d "/var/log/contrail" ];
	then
		sudo mkdir /var/log/contrail
		sudo chmod 777 /var/log/contrail
	fi
	
	# create plugins folder
	if [ ! -d "/var/log/contrail" ];
	then	
		sudo mkdir /etc/neutron/plugins/opencontrail
	fi

	#copy the config files
	sudo cp $HOMEDIR/contrail-install-script/allinone/config/* /etc/contrail/.
    sudo cp $HOMEDIR/contrail-install-script/allinone/config/ContrailPlugin.ini /etc/neutron/plugins/opencontrail/.
	sudo cp $HOMEDIR/contrail-install-script/allinone/systemctl/* /etc/systemd/system/.

}


function update_config{
	# modify the contrail config files
	# modify the sysemctl(if ??)
}

function restart_contrail_services{
	# reload he systemctl
	sudo systemctl daemon-reload

	#create config file folder
	# to
    sudo systemctl start contrail@api
    sudo systemctl start contrail@schema
    sudo systemctl start contrail@svc-monitor
    sudo systemctl start contrail@control
    sudo systemctl start contrail@analytics-api
    sudo systemctl start contrail@query-engine
    sudo systemctl start contrail@collector  
}




#step1
setup_infra_services
configure_rabbitmq
configure_redis
configure_cassandra
#install_contrail
#copy_config
#update_config
#restart_contrail_services
#verify_serices




:'
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


'