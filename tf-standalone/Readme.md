# contrail-install-script


## 1. Introduction

This tutorial helps to install tungsten-fabric (a.k.a) opencontrail (using nixpkgs-tungsten repo).


This tutorial demonstrates Contrail 5.0  on Ubuntu 16.04 VM.



## 2. Installation Procedure

Setup:  I am using Ubuntu 16.04 VM (16GB RAM/4 Core Processor:)


### 1. Contrail Installaion - PART1 

1. Download and run install script 



```
git clone https://github.com/sureshkvl/contrail-install-script
cd contrail-install-script/tf-standalone/
```

Edit the aio_config.sh , and provide the proper input(IPs, interface, hostname etc)

```
./aio_install.sh
```


Note: This script installs the infra services(cassandra, rabbitmq, redis) and contrail services(config,control,analyics services) with default configuration.


### 2. Contrail Installaion - PART2

1. Edit the /etc/contrail/contrail-vrouter-agent.conf and provide proper IP deails.


2. Start the vrouter agent
```
sudo -i
export LC_ALL="C"; unset LANGUAGE
/home/cloud/.nix-profile/bin/contrail-vrouter-agent --config_file /etc/contrail/contrail-vrouter-agent.conf
```
systemctl doesnt work, need to check.???


### 4. Contrail Installaion - PART3

1. Run Contrail PROVISION script 

```
./aio_provision.sh
```


# TESTING

## Simple VM Ping Test

1. source nix path
source /home/cloud/.nix-profile/etc/profile/nix.sh


2. Add Virtual network

contrail-api-cli --ns contrail_api_cli.provision add-vn --project-fqname default-domain:default-project --subnet 20.1.1.0/24 vn1


3. Create a test VM

sudo env PATH=$PATH netns-daemon-start -n default-domain:default-project:vn1 vm1



4. To delete a VM

sudo env PATH=$PATH netns-daemon-stop vm1





# Security Group Test


