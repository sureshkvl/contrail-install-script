# This has to run in compute node / devsack


#Steps:
#1. Load the vrouter module, creating the vhost0 interface  
#2. Run provisioning scripts 
#   a. setup vgw interface and iptables for NAT.

#Prerequisties:
#1. vrouter, vrouter-agents, neutron-plugin installation should have been done.
# neutron plugin??????? location ???

#/lib/modules/3.13.0-112-generic/extra/net/vrouter/vrouter.ko

VIF=/home/cloud/.nix-profile/bin/vif
PROVISION=/home/cloud/.nix-profile/bin/provision_vgw_interface.py



#Global variables
VHOST_INTERFACE_NAME=ens3
VHOST_INTERFACE_CIDR=10.0.1.4/24
VHOST_INTERFACE_IP=10.0.1.4
DEFAULT_GW=10.0.1.1

FLOATING_RANGE=${FLOATING_RANGE:-172.24.4.0/24}
Q_L3_ENABLED=${Q_L3_ENABLED:-True}
VGW_MASQUERADE=${VGW_MASQUERADE:-True}
VR_KMOD_OPTS=${VR_KMOD_OPTS:-"vr_flow_entries=4096 vr_oflow_entries=512 vr_bridge_entries=128"}

#/usr/share/contrail-utils/provision_vrouter.py --host_name devstack --host_ip 10.0.1.3 --api_server_ip 10.0.1.5


# copied from https://github.com/zioc/contrail-devstack-plugin/blob/master/devstack/plugin.sh
function insert_vrouter() {

    if ! lsmod | grep -q vrouter; then
        echo "Inserting vrouter kernel module"
        sudo modprobe vrouter $VR_KMOD_OPTS
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

function remove_vrouter() {

    ! lsmod | grep -q vrouter && return 0

    echo "Removing vrouter kernel module"

    sudo ip addr add $VHOST_INTERFACE_CIDR dev $VHOST_INTERFACE_NAME || true #dhclient may have already done that
    sudo ip route show dev vhost0 scope global | while read route; do
    # Migrate routes back to physical interface
        sudo ip route replace $route dev $VHOST_INTERFACE_NAME || true
    done
    sudo ip addr flush dev vhost0

    sudo $VIF --list | awk '$1~/^$VIF/ {print $1}' |  sed 's|.*/||' | xargs -I % sudo $VIF --delete %
    #NOTE: as it is executed in stack.sh, vrouter-agent shoudn't be running, we should be able to remove vrouter module
    sudo rmmod vrouter
}

#                    vi /usr/share/contrail-utils/provision_vgw_interface.py
#                    Eg. python provision_vgw_interface.py 
#                                        --oper <create | delete>
#                                        --interface vgw1
#                                        --subnets 1.2.3.0/24 7.8.9.0/24
#                                        --routes 8.8.8.0/24 9.9.9.0/24
#                                        --vrf default-domain:admin:vn1:vn1


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

#insert_vrouter
setupgw
