# contrail-install-script




---
[toc]
---











## 1. Introduction

This tutorial helps to install tungsten-fabric (a.k.a) opencontrail (using nixpkgs-tungsten repo) and integreate with openstack.


This tutorial demonstrates Contrail 5.0 + Openstack Queens or Ocata on Ubuntu 16.04 VM.






## 2. Installation Procedure

Setup:  I am using Ubuntu 16.04 VM (16GB RAM/4 Core Processor:)



### Devstack installation

**1. Download **

```
cd 
git clone https://opendev.org/openstack/devstack
cd devstack
git checkout stable/ocata
```


**2. Create local.conf **
vi local.conf


```
[[local|localrc]]
RECLONE=True
HOST_IP=10.0.1.4
SERVICE_TOKEN=mytoken123
ADMIN_PASSWORD=openstack123
MYSQL_PASSWORD=mysql123
RABBIT_PASSWORD=rabbit123
SERVICE_PASSWORD=$ADMIN_PASSWORD
LOGFILE=$DEST/logs/stack.sh.log
LOGDAYS=2
disable_service n-net tempest c-api c-sch c-vol
enable_service q-svc q-agt q-dhcp q-l3 q-meta 
```
Note: provide your HOST_IP.

**3.Start the installation**


```
./stack.sh
```

It will take 15 to 30 mins to complete it.



**4.Stop the below services**


Stop the neutron services (q-svc, q-meta,q-l3, q-dhcp, q-agt) in the screen or systemctl

Stop the nova compute (n-cpu) in the screen or systemctl


### OpenContrail installation

1. Download and run install script 

```
git clone https://github.com/sureshkvl/contrail-install-script
cd contrail-install-script/allinone/aio
./aio_install.sh
```

Note: This script installs the infra services(cassandra, rabbitmq, redis) and contrail services(config,control,analyics services) with default configuration.


2. Setup the cassandra.

Edit /etc/cassandra/cassandra.yaml and enable as below,

```
	#under seed-provider section
	- seeds: "10.0.1.4"
	listen_address: 10.0.1.4
	start_rpc: true
	rpc_address: 10.0.1.4

```

Start the cassandra

```
	sudo service cassandra stop
	sudo service cassandra start

```

3. Setup the redis server

Edit /etc/redis/redis.conf

```
bind 0.0.0.0
```
Note: provide your system IP

ReStart the redis

```
	sudo service redis-server stop
	sudo service redis-server start

```

4. Setting up the rabbimq user

```
sudo rabbitmqctl add_user contrail contrail
sudo rabbitmqctl set_permissions -p / contrail ".*" ".*" ".*"
```


4. Edit the contrail config files (/etc/contrail)
Note: you need to change IP Address, host name


5. Restart the contrail services

```
cd contrail-install-script/contrail
./contrail-services.sh stop
./contrail-services.sh start
./contrail-services.sh status
```

6. check the log files

/var/log/contrail




### VROUTER installation



2. Remove your existing nixpkgs-tungsten folder

3. Run the Vrouter_install script

```
git clone https://github.com/sureshkvl/contrail-install-script
cd contrail-install-script/contrail
./vrouter_install.sh
```

4. check the vrouter kernel module is loaded. 
```
sudo lsmod |grep vrouter
```


5. Modify the vrouter_setup.sh script with relavent IP stuff and run it

NOTE:  if the IP is wrong, system will not be reachable.


```
./vrouter_setup.sh

```


6. Verify the "vhost0" interface created


```
ifconfig
```


7. Modify the neutron config(/etc/neutron/neutron.conf) file

disable  service_plugins, core_plugin line.

```
api_extensions_path = extensions:/usr/local/lib/python2.7/dist-packages/neutron_plugin_contrail/extensions

core_plugin = neutron_plugin_contrail.plugins.opencontrail.contrail_plugin.NeutronPluginContrailCoreV2


[quota]
quota_driver = neutron_plugin_contrail.plugins.opencontrail.quota.driver.QuotaDriver

```
In keystone_auth section, comment the
```
#signing_dir = /var/cache/neutron
#cafile = /opt/stack/data/ca-bundle.pem
```


8. Update /etc/neutron/plugins/opencontrail/ContrailPlugin.ini

```
[APISERVER]
apply_subnet_host_routes = True
api_server_ip = 10.0.1.7
api_server_port = 8082
multi_tenancy = False
```

9.  Edit the cfgm_common (bug)

```
#/usr/local/lib/python2.7/dist-packages/cfgm_common/__init__.py
#SG_NO_RULE_NAME = '__no_rule__'
```


10. Run the neutron with opencontrail plugin conf file in the screen

```
/usr/local/bin/neutron-server --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugins/opencontrail/ContrailPlugin.ini & echo $! >/opt/stack/status/stack/q-svc.pid; fg || echo "q-svc failed to start" | tee "/opt/stack/status/stack/q-svc.failure"
```


11. Include the Contrail VIF driver in the nova.conf file 

Edit /etc/nova/nova.conf, under libvirt section include vif_driver as below,


```
[libvirt]
vif_driver = nova_contrail_vif.contrailvif.VRouterVIFDriver
```


12. Include the nix path in the nova execution search path (/etc/nova/rootwrap.conf)
edit /etc/nova/rootwrap.conf

Update exec_dirs line with /home/cloud/.nix-profile/bin

```
exec_dirs=/sbin,/usr/sbin,/bin,/usr/bin,/usr/local/sbin,/usr/local/bin,/home/cloud/.nix-profile/bin
```


13. Restart the nova services.


14. Edit the /etc/contrail/contrail-vrouter-agent.conf and provide proper IP deails.


15. Start the vrouter agent
```
sudo -i
export LC_ALL="C"; unset LANGUAGE
/home/cloud/.nix-profile/bin/contrail-vrouter-agent --config_file /etc/contrail/contrail-vrouter-agent.conf
```
systemctl doesnt work, need to check.???


16. Provision VGW (Virtual Gateway)

Create  the public network

```
source openrc admin admin
neutron net-create public --router:external True --provider:network_type local
neutron subnet-create --gateway 172.24.4.1 --allocation-pool start=172.24.4.5,end=172.24.4.50 public 172.24.4.0/24
```

17. setup the vgw

Edit the IP details in the vgw_script.sh

Run he below script
>./vgw_setup.sh


**Verify the vgw interface is created**
>ifconfig vgw


18. Run Contrail PROVISION script n CONTRAIL NODE

Edit the script and update the IPs.

```
./provision_vrouter.sh
```




### Quick Testing

Todo



## 2. Checking the Services

Contrail API:

- check 8082(restapi) and 8084(introspect) ports are in listenting mode
- Run Contrail-api-cli and could able to access the objects
- open http://contrail-ip:8084 and see the introspect page



Contrail Schema:



contrail svc monitor:




contrail analytics:






