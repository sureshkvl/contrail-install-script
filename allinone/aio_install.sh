#!/bin/bash

HOMEDIR=/home/cloud
HOSTIP=10.0.1.5

VIF=/home/cloud/.nix-profile/bin/vif
PROVISION=/home/cloud/.nix-profile/bin/provision_vgw_interface.py


#Global variables
VHOST_INTERFACE_NAME=ens3
VHOST_INTERFACE_CIDR=10.0.1.5/24
VHOST_INTERFACE_IP=10.0.1.5
DEFAULT_GW=10.0.1.1

FLOATING_RANGE=${FLOATING_RANGE:-172.24.4.0/24}
Q_L3_ENABLED=${Q_L3_ENABLED:-True}
VGW_MASQUERADE=${VGW_MASQUERADE:-True}
VR_KMOD_OPTS=${VR_KMOD_OPTS:-"vr_flow_entries=4096 vr_oflow_entries=512 vr_bridge_entries=128"}



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


function check_infra_services() {
        #creating rabbit mq users
        echo "Checking REDIS Process status....."
        ps -ef |grep redis
        echo "Checking ZOOKEEPER Process status....."
        ps -ef |grep zookeeper
        echo "Checking RABBITMQ Process status....."
        ps -ef |grep rabbitmq
        echo "Checking CASSANDRA Process status....."
        ps -ef |grep cassandra

}




function install_contrail(){

	cd $HOMEDIR
	git clone https://github.com/sureshkvl/nixpkgs-tungsten
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
	if [ ! -d "/etc/neutron/plugins/opencontrail" ];
	then	
		sudo mkdir /etc/neutron/plugins/opencontrail
	fi

	#copy the config files
	sudo cp $HOMEDIR/contrail-install-script/allinone/config/* /etc/contrail/.
        sudo cp $HOMEDIR/contrail-install-script/allinone/config/ContrailPlugin.ini /etc/neutron/plugins/opencontrail/.
	sudo cp $HOMEDIR/contrail-install-script/allinone/systemctl/* /etc/systemd/system/.

}

function verify_services(){
       echo "checking the contrail services"
}

function restart_contrail_services(){
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

function cleanup_ovs_footprints(){
	sudo ip netns del $(sudo ip netns ls)
	sudo ip netns del $(sudo ip netns ls)

	#remove the ovs bridges
	sudo ifconfig br-int down
	sudo ifconfig br-ex down
	sudo ifconfig br-tun down

	sudo ovs-vsctl del-br br-int
	sudo ovs-vsctl del-br br-ex
	sudo ovs-vsctl del-br br-tun
	sudo service openvswitch-switch stop

}

function build_vrouter(){
        cd $HOMEDIR/nixpkgs-tungsten
	#Build and load the vrouter kernel module,its available only in my sureshkvl repo
	./please build contrail50.vrouterModuleUbuntu_4_4_0_119_generic
	sudo cp ./result/lib/modules/4.4.0-119-generic/extra/net/vrouter/vrouter.ko  /lib/modules/4.4.0-119-generic/.
	sudo insmod ./result/lib/modules/4.4.0-119-generic/extra/net/vrouter/vrouter.ko  $VR_KMOD_OPTS
	sudo lsmod |grep vrouter
}


# copied from https://github.com/zioc/contrail-devstack-plugin/blob/master/devstack/plugin.sh
function setup_vrouter(){

    if ! lsmod | grep -q vrouter; then
        echo "Inserting vrouter kernel module"
        #sudo modprobe vrouter $VR_KMOD_OPTS
        sudo insmod /lib/modules/4.4.0-119-generic/vrouter.ko $VR_KMOD_OPTS
        if [[ ! $? -eq 0 ]]; then
            echo "Failed to insert vrouter kernel module"
            return 1
        fi
    fi

    #Check if vrouter interface have already been added
    if ip link show |grep -q vhost0; then
        return 0
    fi

    DEV_MAC=$(cat /sys/class/net/$VHOST_INTERFACE_NAME/address)

    sudo $VIF --create vhost0 --mac $DEV_MAC
    sudo $VIF --add $VHOST_INTERFACE_NAME --mac $DEV_MAC --vrf 0 --vhost-phys --type physical
    sudo $VIF --add vhost0 $DEVICE --mac $DEV_MAC --vrf 0 --xconnect $VHOST_INTERFACE_NAME --type vhost

    sudo ip link set vhost0 up
    sudo ip addr add $VHOST_INTERFACE_CIDR dev vhost0
    # Migrate routes to vhost0
    sudo ip route show dev $VHOST_INTERFACE_NAME scope global | while read route; do
        sudo ip route replace $route dev vhost0 || true
    done
    sudo ip addr flush dev $VHOST_INTERFACE_NAME
}


function configure_neutron() {
        #to be relooked...dirty code
        sudo sed -i 's/service_plugins = neutron.services.l3_router.l3_router_plugin.L3RouterPlugin/api_extensions_path = extensions:\/usr\/local\/lib\/python2.7\/dist-packages\/neutron_plugin_contrail\/extensions/' /etc/neutron/neutron.conf
        sudo sed -i 's/core_plugin = ml2/core_plugin = neutron_plugin_contrail.plugins.opencontrail.contrail_plugin.NeutronPluginContrailCoreV2/' /etc/neutron/neutron.conf
        sudo sed -i 's/signing_dir/#signing_dir/' /etc/neutron/neutron.conf
        sudo sed -i 's/cafile/#cafile/' /etc/neutron/neutron.conf
}







#step1 - infra services
#======================
#setup_infra_services
#configure_rabbitmq
#configure_redis
#configure_cassandra
#check_infra_services

#step2 - contrail config,contol,analytics
#=======================================
#install_contrail
#copy_config
#restart_contrail_services

#step3 - vrouter
#=================
#cleanup_ovs_footprints
#build_vrouter
#setup_vrouter
#configure_neutron
