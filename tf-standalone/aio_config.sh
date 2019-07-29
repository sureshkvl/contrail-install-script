HOSTNAME=aio1
HOMEDIR=/home/cloud
HOSTIP=10.0.1.5
VHOST_INTERFACE_NAME=ens3
DEFAULT_GW=10.0.1.1


#scripts
VIF=$HOMEDIR/.nix-profile/bin/vif
PROVISION=$HOMEDIR/.nix-profile/bin/provision_vgw_interface.py
PROVISION_VROUTER=/home/cloud/.nix-profile/bin/provision_vrouter.py
PROVISION_CONTROL=/home/cloud/.nix-profile/bin/provision_control.py
PROVISION_LINKLOCAL=/home/cloud/.nix-profile/bin/provision_linklocal.py

#Global variables
VHOST_INTERFACE_CIDR=$HOSTIP/24
VHOST_INTERFACE_IP=$HOSTIP

FLOATING_RANGE=${FLOATING_RANGE:-172.24.4.0/24}
Q_L3_ENABLED=${Q_L3_ENABLED:-True}
VGW_MASQUERADE=${VGW_MASQUERADE:-True}
VR_KMOD_OPTS=${VR_KMOD_OPTS:-"vr_flow_entries=4096 vr_oflow_entries=512 vr_bridge_entries=128"}


CONTRAIL_HOSTNAME=$HOSTNAME
VROUTER_HOSTNAME=$HOSTNAME

#contrail node ip
API_SERVER_IP=$HOSTIP
VROUTER_IP=$HOSTIP
