#!/usr/bin/env bash

# This is a simple script to setup a folder structure for local development.
# To execute this script run the following:
# bash < <(curl -s https://raw.githubusercontent.com/truemark-saltstack-formulas/oracle-formula/master/localdev-local.sh)

set -uex

mkdir -p salt-oracle
cd salt-oracle
mkdir -p pillar
mkdir -p ext_pillar
mkdir -p salt
mkdir -p formulas
cd formulas
if [ ! -d oracle-formula ]; then
    git clone git@github.com:truemark-saltstack-formulas/oracle-formula.git
fi
if [ ! -d proservices-formula ]; then
    git clone git@github.com:truemark-saltstack-formulas/proservices-formula.git
fi
