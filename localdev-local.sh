#!/usr/bin/env bash

mkdir salt-oracle
cd salt-oracle
mkdir pillar
mkdir ext_pillar
mkdir salt
mkdir formulas
cd formulas
git clone git@github.com:truemark-saltstack-formulas/oracle-formula.git 
git clone git@github.com:truemark-saltstack-formulas/proservices-formula.git
