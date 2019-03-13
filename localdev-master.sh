#!/usr/bin/env bash

# This is a simple script to setup a salt master for local development
# To execute this script run the following:
# bash < <(curl -s https://raw.githubusercontent.com/truemark-saltstack-formulas/oracle-formula/master/localdev-master.sh)

# Mount salt-oracle directory

set -uex

tee /etc/rc.local <<EOF
#!/usr/bin/env bash
vmhgfs-fuse .host:/\$(vmware-hgfsclient) /srv -o uid=0 -o gid=0 -o umask=0027
EOF
chmod +x /etc/rc.local

sleep 5

sh /etc/rc.local

# Setup hosts entry for the local salt minion

sed -i -e 's/localhost/localhost salt/'  /etc/hosts

# Allow user to do root stuff without a password

echo 'user ALL=(ALL:ALL) NOPASSWD:ALL' > /etc/sudoers.d/ubuntu

# Install SaltStack

cd /root
curl -L https://bootstrap.saltstack.com -o install_salt.sh
sh install_salt.sh -M stable
rm -f install_salt.sh

service salt-minion restart

# Accept the key for the local minion
output=$(salt-key -Ay --no-color)
echo $output
while [[ "${output}" == *"does not match"* ]]; do
    output=$(salt-key -Ay --no-color)
    echo $output
done

# Do some initial configuration for the salt master
tee /etc/salt/master.d/ext_pillar.conf <<EOF
ext_pillar:
  - file_tree:
      root_dir: /srv/ext_pillar
      follow_dir_links: False
      keep_newline: True
      template: True
      render_default: jinja|yaml
EOF

tee /etc/salt/master.d/file_roots.conf <<EOF
file_roots:
  base:
    - /srv/salt
    - /srv/formulas/oracle-formula
    - /srv/formulas/proservices-formula
EOF

tee /srv/salt/top.sls <<EOF
'$(hostname -f)'
  - tmps.editor
EOF

service salt-master restart
