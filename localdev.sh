#!/usr/bin/env bash

tee /etc/rc.local <<EOF
#!/usr/bin/env bash
vmhgfs-fuse .host:/\$(vmware-hgfsclient) /srv -o uid=0 -o gid=0 -o umask=0027
EOF
chmod +x /etc/rc.local
sleep 5
/etc/rc.local

mkdir -p /srv/salt
mkdir -p /srv/pillar
mkdir -p /srv/ext_pillar

cd /root
curl -L https://bootstrap.saltstack.com -o install_salt.sh
sudo sh install_salt.sh -M stable

