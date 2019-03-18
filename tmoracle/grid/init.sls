{% if pillar['tmoracle']['grid'] is defined %}

{% set oracle_inventory = salt['pillar.get']('tmoracle:oracle_inventory') %}
{% set oracle_base = salt['pillar.get']('tmoracle:oracle_base') %}
{% set sys_password = salt['pillar.get']('tmoracle:grid:sys_password') %}
{% set asmsnmp_password = salt['pillar.get']('tmoracle:grid:asmsnmp_password') %}
{% set home = oracle_base + '/product/' + salt['pillar.get']('tmoracle:grid:home') %}

'grid-home':
  file.directory:
    - name: {{ home }}
    - makedirs: True
    - user: oracle
    - group: oinstall
    - mode: 755

{% for file_name, file_url in salt['pillar.get']('tmoracle:grid:files', {}).items() %}

{%- do salt.log.debug(file_name) -%}

grid-download-{{ file_name }}:
  cmd.run:
    - name: curl -C - {{ file_url }} --output {{ home }}/{{ file_name }}
    - unless: ls {{ home }}/{{ file_name }}.unpacked
    - require:
      - grid-home

grid-unpack-{{ file_name }}:
  cmd.run:
    - name: su -c "unzip -o {{ file_name }}" oracle && touch {{ home }}/{{ file_name }}.unpacked
    - cwd: {{ home }}
    - unless: ls {{ home }}/{{ file_name }}.unpacked
    - require:
      - 'grid-download-{{ file_name }}'

grid-delete-{{ file_name }}:
  cmd.run:
    - name: rm {{ home }}/{{ file_name }}
    - cwd: {{ home }}
    - onlyif: ls {{ home }}/{{ file_name }}
    - require:
      - 'grid-unpack-{{ file_name }}'

{% endfor %}

{% for package_name, package_home in salt['pillar.get']('tmoracle:grid:packages', {}).items() %}

'grid-rpm-{{package_name}}':
  pkg.installed:
    - sources:
      - {{ package_name }}: {{ home }}/{{ package_home }}
    - onlyif:
      - ls {{ package_name }}: {{ home }}/{{ package_home }}


{% endfor %}

nscd:
  service.running:
    - enable: True

asmdba:
  group.present:
    - gid: 54327
    - members:
        - oracle

asmoper:
  group.present:
    - gid: 54328

asmadmin:
  group.present:
    - gid: 54329
    - members:
      - oracle

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

{{ pillar.tmoracle.oracle_inventory }}:
  file.directory:
    - makedirs: True
    - user: oracle
    - group: oinstall
    - mode: 0755

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
    - user: oracle
    - group: oinstall
    - mode: 0750
    - template: jinja
    - require:
      - '{{ home }}.rsp'

Run Grid Setup:
  cmd.run:
    - name: ./gridSetupWrapper.sh {{ home }}.rsp && touch {{ home }}.rsp.ran
    - cwd: {{ home }}
    - unless: ls {{ home }}.rsp.ran
    - require:
        - '{{ home }}/gridSetupWrapper.sh'
        - '{{ home }}.rsp'

Run Post Grid Setup:
  cmd.run:
    - name: /u01/app/12.2.0.1/grid/root.sh
    - cwd: {{ home }}
    - onchanges:
        - Run Grid Setup


'{{ home }}/bin/crsstat':
  file.managed:
    - source: salt://tmoracle/grid/files/crsstat
    - user: oracle
    - group: oinstall
    - mode: 0750

'{{ home }}/bin/crsstat_fill':
  file.managed:
    - source: salt://tmoracle/grid/files/crsstat_full
    - user: oracle
    - group: oinstall
    - mode: 0750

{% endif %}
