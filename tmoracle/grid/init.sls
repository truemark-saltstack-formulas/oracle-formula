{% if pillar['tmoracle']['grid'] is defined %}

{% set oracle_inventory = salt['pillar.get']('tmoracle:oracle_inventory') %}
{% set oracle_base = salt['pillar.get']('tmoracle:oracle_base') %}
{% set download_location = salt['pillar.get']('tmoracle:download_location') %}
{% set sys_password = salt['pillar.get']('tmoracle:grid:sys_password') %}
{% set asmsnmp_password = salt['pillar.get']('tmoracle:grid:asmsnmp_password') %}
{% set home = oracle_base + '/product/' + salt['pillar.get']('tmoracle:grid:home') %}
{% set files = salt['pillar.get']('tmoracle:grid:files', {}) %}

'grid-home':
  file.directory:
    - name: {{ home }}
    - makedirs: True
    - user: oracle
    - group: oinstall
    - mode: 755

'oracle-inventory':
  file.directory:
    - name: {{ oracle_inventory }}
    - makedirs: True
    - user: oracle
    - group: oinstall
    - mode: 0770

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

##########
# Software
##########

# Download Software Files
{% for file_name, file_url in files.items() %}
grid-download-{{ file_name }}:
  cmd.run:
    - name: curl -s -f -C - {{ file_url }} --output {{ home }}/{{ file_name }}
    - unless: ls {{ home }}/gridSetup.sh
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

########
# OPatch
########
{% if pillar['tmoracle']['grid']['opatch'] is defined %}

{% set opatch_file_name = salt['pillar.get']('tmoracle:grid:opatch:file_name') %}
{% set opatch_url = salt['pillar.get']('tmoracle:grid:opatch:url') %}

# Download OPatch Files
grid-opatch-download-{{ opatch_file_name }}:
  cmd.run:
    - name: curl -s -f {{ opatch_url }} --output {{ download_location }}/grid/patches/{{ opatch_file_name }}
    - unless: ls '{{ download_location }}/grid/patches/{{ opatch_file_name }}'
    - require:
      - grid-download-location-patches

grid-opatch-unpack-{{ opatch_file_name }}:
  cmd.run:
    - name: su -c "cd {{ home }}; unzip -qq -o {{ download_location }}/grid/patches/{{ opatch_file_name }}" oracle
    - onchanges:
      - grid-opatch-download-{{ opatch_file_name }}

{% endif %}

################################
# Cumulative Patch Updates (CPU)
################################
{% if pillar['tmoracle']['grid']['cpu'] is defined %}

{% set cpu_id = salt['pillar.get']('tmoracle:grid:cpu:id') %}
{% set cpu_files = salt['pillar.get']('tmoracle:grid:cpu:files', {}) %}

'grid-download-location-patches':
  file.directory:
    - name: {{ download_location }}/grid/patches
    - makedirs: True
    - user: oracle
    - group: oinstall
    - mode: 0755

# Download Patch Files
{% for cpu_file_name, cpu_url in cpu_files.items() %}
grid-cpu-download-{{ cpu_file_name }}:
  cmd.run:
    - name: curl -s -f {{ cpu_url }} --output {{ download_location }}/grid/patches/{{ cpu_file_name }}
    - unless: ls {{ download_location }}/grid/patches/{{ cpu_id }}
    - require:
      - grid-download-location-patches
{% endfor %}

# Unpack & Delete Patch Files
{% for cpu_file_name, cpu_url in cpu_files.items() %}
grid-cpu-unpack-{{ cpu_file_name }}:
  cmd.run:
    - name: su -c "unzip -qq -o {{ cpu_file_name }}" oracle
    - cwd: '{{ download_location }}/grid/patches'
    - onlyif: ls {{ download_location }}/grid/patches/{{ cpu_file_name }}
    - require:
      - grid-cpu-download-{{ cpu_file_name }}

grid-cpu-delete-{{ cpu_file_name }}:
  cmd.run:
    - name: rm -f {{ download_location }}/grid/patches/{{ cpu_file_name }}
    - onlyif: ls {{ download_location }}/grid/patches/{{ cpu_file_name }}
    - require:
      - grid-cpu-unpack-{{ cpu_file_name }}
{% endfor %}

{% endif %}

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
      # TODO This should not be hard coded
      oracle_diskgroup: DATA
      oracle_disk: DATA1
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

Run Grid Setup:
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

{% endif %}
