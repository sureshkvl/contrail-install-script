#this has to run in the contrailnode

#sudo vi /usr/share/contrail-utils/provision_vrouter.py
#python provision_vrouter.py --host_name a3s30.contrail.juniper.net
#                                        --host_ip 10.1.1.1
#                                        --api_server_ip 127.0.0.1
#                                        --api_server_port 8082
#                                        --api_server_use_ssl False
#                                        --oper <add | del>
#                                        [--dpdk-enabled]




CONTRAIL_HOSTNAME=contrail
VROUTER_HOSTNAME=devstack

#contrail node ip
API_SERVER_IP=10.0.1.5

#devstack ip
VROUTER_IP=10.0.1.3
NOVA_SERVICE_HOST=10.0.1.3

#VIF=/home/cloud/.nix-profile/bin/vif
PROVISION_VROUTER=/home/cloud/.nix-profile/bin/provision_vrouter.py
PROVISION_CONTROL=/home/cloud/.nix-profile/bin/provision_control.py
PROVISION_LINKLOCAL=/home/cloud/.nix-profile/bin/provision_linklocal.py


sudo $PROVISION_VROUTER --api_server_ip $API_SERVER_IP \
            --api_server_port 8082 --host_ip $VROUTER_IP --host_name VROUTER_HOSTNAME \
            --oper add  

#sudo vi /usr/share/contrail-utils/provision_control.py
#        Eg. python provision_control.py --host_name a3s30.contrail.juniper.net
#                                        --host_ip 10.1.1.1
#                                        --router_asn 64512
#                                        --ibgp_auto_mesh|--no_ibgp_auto_mesh
#                                        --api_server_ip 127.0.0.1
#                                         --api_server_port 8082
#                                         --api_server_use_ssl False
#                                         --oper <add | del>
#                                         --md5 <key value>|None(optional)
#                                         --graceful_restart_time 100
#                                         --long_lived_graceful_restart_time 100
#                                         --end_of_rib_time 300
#                                         --set_graceful_restart_parameters False
#                                         --graceful_restart_bgp_helper_enable False
#                                         --graceful_restart_xmpp_helper_enable False
#                                         --graceful_restart_enable False
sudo $PROVISION_CONTROL --host_name $CONTRAIL_HOSTNAME --host_ip $API_SERVER_IP \
             --router_asn 64512  --api_server_ip $API_SERVER_IP --api_server_port 8082 --oper add


#sudo vi /usr/share/contrail-utils/provision_linklocal.py
#        Eg. python provision_metadata.py 
#                                        --api_server_ip 127.0.0.1
#                                        --api_server_port 8082
#                                        --api_server_use_ssl False
#                                        --linklocal_service_name name
#                                        --linklocal_service_ip 1.2.3.4
#                                        --linklocal_service_port 1234
#                                        --ipfabric_dns_service_name fabric_server_name
#                                        --ipfabric_service_ip 10.1.1.1
#                                        --ipfabric_service_port 5775
#                                        --oper <add | delete>
sudo $PROVISION_LINKLOCAL  --api_server_ip $API_SERVER_IP \
            --oper add --linklocal_service_name metadata --linklocal_service_ip 169.254.169.254 \
--linklocal_service_port 80 --ipfabric_service_ip $NOVA_SERVICE_HOST --ipfabric_service_port 8775