# contrail-install-script


## 1. Introduction

This tutorial helps to install tungsten-fabric (a.k.a) opencontrail (using nixpkgs-tungsten repo) and integreate with openstack.


This tutorial demonstrates Contrail 5.0 + Openstack Ocata on Ubuntu 16.04 VM.



## 2. Installation Procedure

Setup:  I am using Ubuntu 16.04 VM (16GB RAM/4 Core Processor:)



### A. Devstack installation

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



### B. Contrail Installaion - PART1 

1. Download and run install script 



```
git clone https://github.com/sureshkvl/contrail-install-script
cd contrail-install-script/allinone/
```

Edit the aio_install.sh , and provide the proper input(IPs, interface, hostname etc)

```
./aio_install.sh
```


Note: This script installs the infra services(cassandra, rabbitmq, redis) and contrail services(config,control,analyics services) with default configuration.


### C. Contrail Installaion - PART2

**Manual steps**

1.  Edit the cfgm_common package (bug)

-  sudo vi  /usr/local/lib/python2.7/dist-packages/cfgm_common/__init__.py
- add this below line
```
SG_NO_RULE_NAME = '__no_rule__'
```


2. Run the neutron with opencontrail plugin conf file in the screen

```
/usr/local/bin/neutron-server --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugins/opencontrail/ContrailPlugin.ini & echo $! >/opt/stack/status/stack/q-svc.pid; fg || echo "q-svc failed to start" | tee "/opt/stack/status/stack/q-svc.failure"
```


3. Include the Contrail VIF driver in the nova.conf file 

Edit /etc/nova/nova.conf, under libvirt section include vif_driver as below,


```
[libvirt]
vif_driver = nova_contrail_vif.contrailvif.VRouterVIFDriver
```


4. Include the nix path in the nova execution search path (/etc/nova/rootwrap.conf)
edit /etc/nova/rootwrap.conf

Update exec_dirs line with /home/cloud/.nix-profile/bin

```
exec_dirs=/sbin,/usr/sbin,/bin,/usr/bin,/usr/local/sbin,/usr/local/bin,/home/cloud/.nix-profile/bin
```

5. Restart the nova compute services.


6. Edit the /etc/contrail/contrail-vrouter-agent.conf and provide proper IP deails.


7. Start the vrouter agent
```
sudo -i
export LC_ALL="C"; unset LANGUAGE
/home/cloud/.nix-profile/bin/contrail-vrouter-agent --config_file /etc/contrail/contrail-vrouter-agent.conf
```
systemctl doesnt work, need to check.???




### D. Contrail Installaion - PART3

1. Run Contrail PROVISION script 

Edit the script and update the IPs.

```
./aio_provision.sh
```

