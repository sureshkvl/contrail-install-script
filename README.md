# contrail-install-script




---
[toc]
---











## 1. Introduction

This tutorial helps to install tungsten-fabric (a.k.a) opencontrail (using nixpkgs-tungsten repo) and integreate with openstack.


This tutorial demonstrates Contrail 5.0 + Openstack Ocata on Ubuntu 16.04 VM.






## 2. Installation Procedue

Setup:  I am using Ubuntu 16.04 VM (16GB RAM/4 Core Processor:)



### Devstack installation





### OpenContrail Installation



lease with Devstack OCATA Release


**Part1:**

- Install infra, tungsten-fabric config, control, analytics modules
- configure
- start.

**Part2:**

- Install vrouter (kernel module, vrouter agent) 
- configure
- modify the existing neutron configs / stop services
- provision 
- start 



Setup:

I am using two Ubuntu 16.04 VMs




## Part1 - Installing Tungsten Fabric Control Modules 

Ubuntu 16.04 prd vm

```
git clone https://github.com/sureshkvl/contrail-install-script
cd contrail-install-script/contrail
./contrail_install.sh
```


- Edit /etc/cassandra/cassandra.yaml and enable as below,


	```
	#under seed-provider section
	- seeds: "10.0.1.4"
	listen_address: 10.0.1.4
	start_rpc: true
	rpc_address: 10.0.1.4

	```

- restart cassandra
```
sudo service cassandra restart
```

- Modify the "openstack keystone auth IP & creds" in  /etc/contrail/contrail-api.conf
- Modify the "openstack keystone auth IP & creds" in  /etc/contrail/vnc_api_lib.ini


- restart contrail-api
   sudo systemctl restart contrail@api



**Verify:**

- sudo systemctl status contrail@api
- sudo systemctl status contrail@schema
- sudo systemctl status contrail@svc-monitor
- sudo systemctl status contrail@control
- sudo systemctl status contrail@analytics-api
- sudo systemctl status contrail@collector
- sudo systemctl status contrail@query-engine

**Logs**

logs are located in /var/log/contrail folder


**how to use contrail api cli**

>contrail-api-cli --os-username admin --os-password openstack123 shell









### Installing Tungsten Fabric VROUTER Module in Compute Node of Openstack (Part2)

Ubuntu 16.04 vm installed with DEVSTACK OCATA version


1. Stop the neutron services (q-svc, q-meta,q-l3, q-dhcp, q-agt)


2. Run the Vrouter_install script

```
git clone https://github.com/sureshkvl/contrail-install-script
cd contrail-install-script/vrouter
./vrouter_install.sh
```

check the vrouter kernel module is loaded. 
>sudo lsmod |grep vrouter



2. Modify the vrouter_setup.sh script with relavent IP stuff and run it

NOTE:  if the IP is wrong, system will not be reachable.


```
./vrouter_setup.sh

```

3. Verify the "vhost0" interface created


```
ifconfig
```



6. Modify the neutron config(/etc/neutron/neutron.conf) file

**include below lines**

```
api_extensions_path = extensions:/usr/local/lib/python2.7/dist-packages/neutron_plugin_contrail/extensions

core_plugin = neutron_plugin_contrail.plugins.opencontrail.contrail_plugin_v3.NeutronPluginContrailCoreV3
[quota]
quota_driver = neutron_plugin_contrail.plugins.opencontrail.quota.driver.QuotaDriver

```

disable  service_plugins, core_plugin line.



5. Create /etc/neutron/plugins/opencontrail/ContrailPlugin.ini
sudo vi /etc/neutron/plugins/opencontrail/ContrailPlugin.ini

```
[APISERVER]
apply_subnet_host_routes = True
api_server_ip = 10.0.1.7
api_server_port = 8082
multi_tenancy = False
```

Note API server IP



6. Modify the neutron systemctl(start service) file /etc/systemd/system/devstack@q-svc.service

Modify Execstart file as below,

ExecStart = /usr/local/bin/neutron-server --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugins/opencontrail/ContrailPlugin.ini


- Edit the cfgm_common 

```
#/usr/local/lib/python2.7/dist-packages/cfgm_common/__init__.py
#SG_NO_RULE_NAME = '__no_rule__'
```

6. start the neutron server
```
systemctl daemon-reload
sudo systemctl start devstack@q-svc
sudo systemctl status devstack@q-svc
journalctl -f -u devstack@q-svc
```




4. Edit the /etc/contrail/contrail-vrouter-agent.conf and provide proper IP deails.

5. Start the vrouter agent
```
sudo -i
export LC_ALL="C"; unset LANGUAGE
/home/cloud/.nix-profile/bin/contrail-vrouter-agent --config_file /etc/contrail/contrail-vrouter-agent.conf
```
systemctl doesnt work, need to check.???

check the logs in /var/log/contrail folder




7. Create  the public network

```
source openrc admin admin

neutron net-create public --router:external True --provider:network_type local

neutron subnet-create --gateway 172.24.4.1 --allocation-pool start=172.24.4.5,end=172.24.4.50 public 172.24.4.0/24
```

8. set up the vgw

Edit the IP details in the vgw_script.sh

Run he below script
>./vgw_setup.sh

```
cloud@dev2:~/contrail-install-script/vrouter$ ./vgw_setup.sh                                                 [30/360]
Creating virtual-gateway ...
/nix/store/1lq4yf543fdjjjc18fd12sds88c47v5a-contrail-vrouter-utils-5.0/bin/vif --create vgw --mac 00:00:5e:00:01:00
ifconfig vgw up
route add -net 172.24.4.0/24 dev vgw
Done creating virtual-gateway...
cloud@dev2:~/contrail-install-script/vrouter$
```

**Verify the vgw interface is created**
>ifconfig vgw
>ip route 


PROVISION the CONTRAIL  in CONTRAIL NODE
==========================================


9. Update the hostname in /etc/hosts file of both devstack and contrail vm.

vi /etc/hosts

```
10.0.1.6 c2
10.0.1.4 dev2
```


10. Edit the provision_vrouter.sh script, and provide correct IP details and hostname
Run this script

./provision_vrouter.sh




11. Run the control node manually

sudo /home/cloud/.nix-profile/bin/contrail-control --conf_file /etc/contrail/contrail-control.conf

