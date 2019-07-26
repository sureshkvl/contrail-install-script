#!/bin/bash


DEVSTACKDIR=/home/cloud/devstack
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


CONTRAIL_HOSTNAME=aio3
VROUTER_HOSTNAME=aio3

#contrail node ip
API_SERVER_IP=10.0.1.5

#devstack ip
VROUTER_IP=10.0.1.5
NOVA_SERVICE_HOST=10.0.1.5

#VIF=/home/cloud/.nix-profile/bin/vif
PROVISION_VROUTER=/home/cloud/.nix-profile/bin/provision_vrouter.py
PROVISION_CONTROL=/home/cloud/.nix-profile/bin/provision_control.py
PROVISION_LINKLOCAL=/home/cloud/.nix-profile/bin/provision_linklocal.py






function create_publicnw() {
    source $DEVSTACKDIR/openrc admin admin
    neutron net-create public --router:external True --provider:network_type local
    neutron subnet-create --gateway 172.24.4.1 --allocation-pool start=172.24.4.5,end=172.24.4.50 public 172.24.4.0/24
}

function setupgw(){

        if [[ "$Q_L3_ENABLED" == "True" ]]; then
        sudo $PROVISION --oper create \
            --interface vgw --subnets $FLOATING_RANGE --routes 0.0.0.0/0 \
            --vrf "default-domain:admin:public:public"
        if [[ "$VGW_MASQUERADE" == "True" ]] && ! sudo iptables -t nat -C POSTROUTING -s $FLOATING_RANGE -j MASQUERADE > /dev/null 2>&1; then
            sudo iptables -t nat -A POSTROUTING -s $FLOATING_RANGE -j MASQUERADE
        fi
    fi
}

function provision_vrouter(){

        sudo $PROVISION_VROUTER --api_server_ip $API_SERVER_IP \
            --api_server_port 8082 --host_ip $VROUTER_IP --host_name VROUTER_HOSTNAME \
            --oper add 
        
        sudo $PROVISION_CONTROL --host_name $CONTRAIL_HOSTNAME --host_ip $API_SERVER_IP \
             --router_asn 64512  --api_server_ip $API_SERVER_IP --api_server_port 8082 --oper add

        sudo $PROVISION_LINKLOCAL  --api_server_ip $API_SERVER_IP \
             --oper add --linklocal_service_name metadata --linklocal_service_ip 169.254.169.254 \
             --linklocal_service_port 80 --ipfabric_service_ip $NOVA_SERVICE_HOST --ipfabric_service_port 8775



}

create_publicnw
setupgw
provision_vrouter
