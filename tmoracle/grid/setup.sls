{% if pillar['tmoracle']['grid'] is defined %} # start if grid

{% set oracle_inventory = salt['pillar.get']('tmoracle:oracle_inventory') %}
{% set oracle_base = salt['pillar.get']('tmoracle:oracle_base') %}
{% set home = oracle_base + '/product/' + salt['pillar.get']('tmoracle:grid:home') %}
{%- do salt.log.debug(home) -%}
{%- do salt.log.debug('MOOOOOO') -%}
{% set sys_password = salt['pillar.get']('tmoracle:grid:sys_password') %}
{% set asmsnmp_password = salt['pillar.get']('tmoracle:grid:asmsnmp_password') %}
{% set initial_asm_diskgroup = salt['pillar.get']('tmoracle:grid:initial_asm_diskgroup') %}
{% set initial_asm_disk = salt['pillar.get']('tmoracle:grid:initial_asm_disk') %}
{% set files = salt['pillar.get']('tmoracle:grid:files', {}) %}

#################
# Enable Services
#################

nscd:
  service.running:
    - enable: True


##############
# Setup Groups
##############

asmdba:
  group.present:
    - gid: 54327
    - members:
      - oracle

asmoper:
  group.present:
    - gid: 54328
    - members:
      - oracle

asmadmin:
  group.present:
    - gid: 54329
    - members:
      - oracle

############
# Setup Bash
############

'/home/oracle/.bashrc.grid':
  file.managed:
    - source: salt://tmoracle/grid/files/bashrc.grid.jinja
    - user: oracle
    - group: oinstall
    - mode: 0664
    - template: jinja
    - context:
      home: {{ home }}
      oracle_base: {{ oracle_base }}

'/home/oracle/.bashrc.d/grid.bashrc':
  file.managed:
    - source: salt://tmoracle/grid/files/grid.bashrc.jinja
    - user: oracle
    - group: oinstall
    - mode: 0644
    - template: jinja

###########################
# Setup Grid Home Directory
###########################
'grid-home':
  file.directory:
    - name: {{ home }}
    - makedirs: True
    - user: oracle
    - group: oinstall
    - mode: 755

##########
# Software
##########
# Download Software Files
{% for file_name, file_url in files.items() %}
'grid-download-{{ file_name }}':
  cmd.run:
    - name: 'curl -s -f -C - {{ file_url }} --output {{ home }}/{{ file_name }}'
    - unless: 'ls {{ home }}/gridSetup.sh'
    - require:
      - grid-home
{% endfor %}

# Unpack & Delete Software Files
{% for file_name, file_url in files.items() %}
grid-unpack-{{ file_name }}:
  cmd.run:
    - name: su -c "unzip -qq -o {{ file_name }}" oracle
    - cwd: {{ home }}
    - onlyif: ls {{ home }}/{{ file_name }}
    - require:
      - grid-download-{{ file_name }}

grid-delete-{{ file_name }}:
  cmd.run:
    - name: rm -f {{ home }}/{{ file_name }}
    - onlyif: ls {{ home }}/{{ file_name }}
    - require:
      - grid-unpack-{{ file_name }}
{% endfor %}

##################
# Install Packages
##################

{% for package_name, package_home in salt['pillar.get']('tmoracle:grid:packages', {}).items() %}
'grid-rpm-{{package_name}}':
  pkg.installed:
    - sources:
      - {{ package_name }}: {{ home }}/{{ package_home }}
    - onlyif:
      - ls {{ package_name }}: {{ home }}/{{ package_home }}
{% endfor %}

############
# Grid Setup
############

'{{ home }}.rsp':
  file.managed:
    - source: salt://tmoracle/grid/files/grid.rsp.jinja
    - user: oracle
    - group: oinstall
    - mode: 0640
    - template: jinja
    - context:
      oracle_inventory: {{ oracle_inventory }}
      oracle_base: {{ oracle_base }}
      asm_diskgroup: {{ initial_asm_diskgroup }}
      asm_disks: /dev/oracleasm/disks/{{ initial_asm_disk }}
      sys_password: {{ sys_password }}
      asmsnmp_password: {{ asmsnmp_password }}

'{{ home }}/gridSetupWrapper.sh':
  file.managed:
    - source: salt://tmoracle/grid/files/gridSetupWrapper.sh.jinja
    - user: root
    - group: root
    - mode: 0700
    - template: jinja
    - require:
      - '{{ home }}.rsp'
    - context:
      oracle_inventory: {{ oracle_inventory }}
      response_file: {{ home }}.rsp

grid-setup:
  cmd.run:
    - name: ./gridSetupWrapper.sh
    - cwd: {{ home }}
    - unless: ls {{ home }}/bin/crsctl
    - require:
      - '{{ home }}/gridSetupWrapper.sh'
      - '{{ home }}.rsp'

'{{ home }}/bin/crsstat':
  file.managed:
    - source: salt://tmoracle/grid/files/crsstat
    - user: oracle
    - group: oinstall
    - mode: 0750

'{{ home }}/bin/crsstat_full':
  file.managed:
    - source: salt://tmoracle/grid/files/crsstat_full
    - user: oracle
    - group: oinstall
    - mode: 0750

{% endif %} # end if grid
