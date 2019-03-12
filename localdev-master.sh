#!/usr/bin/env bash

# This is a simple script to setup a salt master for local development
# To execute this script run the following:
# bash < <(curl -s https://raw.githubusercontent.com/truemark-saltstack-formulas/oracle-formula/master/localdev-master.sh)

tee /etc/rc.local <<EOF
#!/usr/bin/env bash
vmhgfs-fuse .host:/\$(vmware-hgfsclient) /srv -o uid=0 -o gid=0 -o umask=0027
EOF
chmod +x /etc/rc.local

sleep 5

sh /etc/rc.local

cd /root

curl -L https://bootstrap.saltstack.com -o install_salt.sh
sudo sh install_salt.sh -M stable

