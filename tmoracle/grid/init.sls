{% if pillar['tmoracle']['grid'] is defined %}

{% set home = salt['pillar.get']('tmoracle:grid:home') %}

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
        - grid-download-{{ file_name }}

grid-delete-{{ file_name }}:
  cmd.run:
    - name: rm {{ home }}/{{ file_name }}
    - cwd: {{ home }}
    - onlyif: ls {{ home }}/{{ file_name }}
    - require:
        - grid-unpack-{{ file_name }}

  {% endfor %}

  {% for package_name, package_home in salt['pillar.get']('tmoracle:grid:packages', {}).items() %}

'grid-rpm-{{package_name}}':
  pkg.installed:
    - sources:
        - {{ package_name }}: {{ home }}/{{ package_home }}

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
    - mode: 664
    - template: jinja

{{ pillar.tmoracle.oracle_inventory }}:
  file.directory:
    - makedirs: True
    - user: oracle
    - group: oinstall
    - mode: 755

# TODO Add alias and echo to .bashrc

{% endif %}
