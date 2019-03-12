#!/usr/bin/env bash

# This is a simple script to setup a folder structure for local development.
# To execute this script run the following:
# bash < <(curl -s https://raw.githubusercontent.com/truemark-saltstack-formulas/oracle-formula/master/localdev-local.sh)

set -uex

mkdir salt-oracle
cd salt-oracle
mkdir pillar
mkdir ext_pillar
mkdir salt
mkdir formulas
cd formulas
git clone git@github.com:truemark-saltstack-formulas/oracle-formula.git 
git clone git@github.com:truemark-saltstack-formulas/proservices-formula.git
