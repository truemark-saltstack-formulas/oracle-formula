{% if pillar['tmoracle']['grid'] is defined %}

{% set location = salt['pillar.get']('tmoracle:grid:location') %}

'grid-location':
  file.directory:
    - name: {{ location }}
    - makedirs: True
    - user: oracle
    - group: oinstall
    - mode: 755

{% for file_name, file_url in salt['pillar.get']('tmoracle:grid:files', {}).items() %}

{%- do salt.log.debug(file_name) -%}

grid-download-{{ file_name }}:
  cmd.run:
    - name: curl {{ file_url }} --output {{ location }}/{{ file_name }}
    - unless: ls {{ location }}/{{ file_name }}.unpacked
    - require:
        - grid-location

grid-unpack-{{ file_name }}:
  cmd.run:
    - name: su -c "unzip -o {{ file_name }}" oracle && touch {{ location }}/{{ file_name }}.unpacked
    - cwd: {{ location }}
    - unless: ls {{ location }}/{{ file_name }}.unpacked
    - require:
        - grid-download-{{ file_name }}

grid-delete-{{ file_name }}:
  cmd.run:
    - name: rm {{ location }}/{{ file_name }}
    - cwd: {{ location }}
    - onlyif: ls {{ location }}/{{ file_name }}
    - require:
        - grid-unpack-{{ file_name }}

  {% endfor %}

  {% for package_name, package_location in salt['pillar.get']('tmoracle:grid:packages', {}).items() %}

'grid-rpm-{{package_name}}':
  pkg.installed:
    - sources:
        - {{ package_name }}: {{ location }}/{{ package_location }}

  {% endfor %}

{% endif %}
