# oracle-formula

This is a saltstack formula used to install and configure Oracle database software.

## Local Development

The following instructions are geared toward the [TrueMark](https://www.truemark.io) Professional Services
team. You may need to modify or tweak these instructions for your own setup. These instructions assume the
following:

* You are running OSX
* You have VMware Fusion Professional installed
* You have downloaded the following ISO images
    * [truemark-vmware-ol-7.6-server-amd64-20190223-083106.iso](http://download.truemark.io/oracle/Oracle%20Linux%207/truemark-vmware-ol-7.6-server-amd64-20190223-083106.iso)
    * [truemark-vmware-ubuntu-18.04.1-server-amd64-20190305-104144.iso](http://download.truemark.io/iso/truemark-vmware-ubuntu-18.04.1-server-amd64-20190305-104144.iso)
    
Assuming you have the pre-requisites ready, the following steps will get you a working local development environment
with a master and minion to work with.

1. On your local machine, execute the localdev-local.sh script. This will create a "salt-oracle" directory in
the directory you execute the script and setup a good folder structure for salt.

    ```bash
    bash < <(curl -s https://raw.githubusercontent.com/truemark-saltstack-formulas/oracle-formula/master/localdev-local.sh)
    ```
    
2. Using the truemark-vmware-ubuntu-18.04.1-server-amd64-20190305-104144.iso create an Ubuntu virtual machine with the following
specifications:

  * 2 vCPU
  * 2 GB RAM
  * 30 GB Disk
  
    Do **not** use the easy install option. This specific ISO will auto-install Ubuntu.
    
    We recommend you name the VM "Oracle Salt Master".

    Once installed you can log in with the following credentials
    
    * Username: user
    * Password: truemark
    
    Optionally you can also use the Ubuntu ISO from https://www.ubuntu.com/download/server and manually do a minimal install.
    
3. Using the "Shared Folders" feature of VMware Fusion. Share the "salt-oracle" folder with your virtual machine from step 2.

4. SSH to the Oracle Salt Master virtual machine you setup and execute the following as the root user

    ```bash
    bash < <(curl -s https://raw.githubusercontent.com/truemark-saltstack-formulas/oracle-formula/master/localdev-master.sh)
    ```
    
    This will install the salt master, minion and provide some initial configuration. This script also mounts the
    share you created in step 3 to /srv.

5. Using the truemark-vmware-ol-7.6-server-amd64-20190223-083106.iso create an Oracle Linux virtual machine with the following
specifications:

  * 2 vCPU
  * 2 GB RAM
  * 30 GB Disk 1
  * 50 GB Disk 2
  * 50 GB Disk 3
  
  The ISO above will auto-install Oracle Linux.
  
  We recommend you name the VM "Oracle Salt Minion"
  
  Once installed you can log in with the following credentials
  
  * Username: user
  * Password: truemark
  
  Optionally you can also use the Oracle Linux ISO from https://www.oracle.com/technetwork/server-storage/linux/downloads/index.html
  and do a minimal install.
  
6. SSH to the Oracle Salt Minion virtual machine you setup and execute the following as the root user

    ```bash
    bash < <(curl -s https://raw.githubusercontent.com/truemark-saltstack-formulas/oracle-formula/master/localdev-minion.sh)
    ```
    
    This script will prompt you for the IP address of your salt master and install and configure the salt minion for you.
    
    
You should now have a fully working local development environment.
You can verify your minions are up by running the following on your master.

```bash
salt-run manage.up
salt '*' test.ping
```