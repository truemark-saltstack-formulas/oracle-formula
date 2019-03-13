#!/usr/bin/env bash

# This is a simple script to setup a salt minion for local development
# To execute this script run the following:
# SALT_MASTER="PUT IP ADDRESS HERE" bash < <(curl -s https://raw.githubusercontent.com/truemark-saltstack-formulas/oracle-formula/master/localdev-minion.sh)

set -uex

# Setup access to salt master

echo "${SALT_MASTER} salt" >> /etc/hosts

# Install SaltStack

cd /root
curl -L https://bootstrap.saltstack.com -o install_salt.sh
sh install_salt.sh stable
rm -f install_salt.sh

tee /etc/salt/minion.d/loglevel.conf <<EOF
log_level: debug
EOF

service salt-minion restart
