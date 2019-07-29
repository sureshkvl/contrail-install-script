#!/bin/bash
source ./aio_config.sh

function provision_vrouter(){

        sudo $PROVISION_VROUTER --api_server_ip $API_SERVER_IP \
            --api_server_port 8082 --host_ip $VROUTER_IP --host_name $VROUTER_HOSTNAME \
            --oper add 
        
        sudo $PROVISION_CONTROL --host_name $CONTRAIL_HOSTNAME --host_ip $API_SERVER_IP \
             --router_asn 64512  --api_server_ip $API_SERVER_IP --api_server_port 8082 --oper add

        sudo $PROVISION_LINKLOCAL  --api_server_ip $API_SERVER_IP \
             --oper add --linklocal_service_name metadata --linklocal_service_ip 169.254.169.254 \
             --linklocal_service_port 80 --ipfabric_service_ip $NOVA_SERVICE_HOST --ipfabric_service_port 8775

}

provision_vrouter
