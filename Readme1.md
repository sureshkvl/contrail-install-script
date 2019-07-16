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
disable_service n-net tempest
enable_service q-svc q-agt q-dhcp q-l3 q-meta 
```
Note: provide your HOST_IP.

**2.Start the installation**


```
./stack.sh
```

It will take 15 to 30 mins to complete it.



### OpenContrail installation

1. Download and run install script 

```
git clone https://github.com/sureshkvl/contrail-install-script
cd contrail-install-script/contrail
./contrail_install.sh
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
bind 10.0.1.3
```
Note: provide your system IP

ReStart the redis

```
	sudo service redis-server stop
	sudo service redis-server start

```

4. Edit the contrail config files (/etc/contrail)
Note: you need to change IP Address, host name


5. Restart the contrail services

```
cd contrail-install-script/contrail
./contrail-services.sh stop
./contrail-services.sh start
```




