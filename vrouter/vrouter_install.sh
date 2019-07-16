#!/bin/bash

#make sure you stop the q-svc,q-agt,q-l3, q-meta

sudo apt-get update
sudo apt-get install -y git


# Stop the neutron services
#sudo systemctl stop devstack@q-svc
#sudo systemctl stop devstack@q-l3
#sudo systemctl stop devstack@q-meta
#sudo systemctl stop devstack@q-dhcp
#sudo systemctl stop devstack@q-agt

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



#create config file folder
sudo mkdir /etc/contrail
#create log folder
sudo mkdir /var/log/contrail
sudo chmod 777 /var/log/contrail


sudo mkdir /etc/neutron/plugins/opencontrail


cd
sudo cp contrail-install-script/vrouter/config/contrail-vrouter-agent.conf /etc/contrail/.
sudo cp contrail-install-script/vrouter/config/ContrailPlugin.ini /etc/neutron/plugins/opencontrail/.

#sudo cp contrail-install-script/vrouter/systemctl/contrail@vrouter-agent.service /etc/systemd/system/.


# 
cd
git clone https://github.com/sureshkvl/nixpkgs-tungsten
cd nixpkgs-tungsten
./please init

#nix profile
. /home/cloud/.nix-profile/etc/profile.d/nix.sh
#Build and load the vrouter kernel module,its available only in my sureshkvl repo
./please build contrail50.vrouterModuleUbuntu_4_4_0_119_generic
sudo insmod ./result/lib/modules/4.4.0-119-generic/extra/net/vrouter/vrouter.ko 
sudo lsmod |grep vrouter

#install the vrouter agent
./please install contrail50.vrouterAgent
./please install contrail50.vrouterNetNs
./please install contrail50.vrouterPortControl
./please install contrail50.vrouterUtils
# provision scripts are available in configutils package
./please install contrail50.configUtils



# build and install relavent python packages
./please build contrail50.pythonPackages.contrail_neutron_plugin
sudo cp ./result/lib/python2.7/site-packages/* /usr/local/lib/python2.7/dist-packages/. -rf

./please build contrail50.pythonPackages.vnc_api
sudo cp ./result/lib/python2.7/site-packages/* /usr/local/lib/python2.7/dist-packages/. -rf

./please build contrail50.pythonPackages.cfgm_common
sudo cp ./result/lib/python2.7/site-packages/* /usr/local/lib/python2.7/dist-packages/. -rf

./please build contrail50.pythonPackages.contrail_vrouter_api
sudo cp ./result/lib/python2.7/site-packages/* /usr/local/lib/python2.7/dist-packages/. -rf

./please build contrail50.pythonPackages.vnc_openstack
sudo cp ./result/lib/python2.7/site-packages/* /usr/local/lib/python2.7/dist-packages/. -rf

#error expected - when we start the neutron server
#/usr/local/lib/python2.7/dist-packages/cfgm_common/__init__.py
#SG_NO_RULE_NAME = '__no_rule__'
