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
    - unless: ls {{ location }}/{{ file_name }}
    - require:
        - grid-location

grid-unpack-{{ file_name }}:
  cmd.run:
    - name: unzip -o {{ file_name }} && touch {{ location }}/{{ file_name }}.unpacked
    - cwd: {{ location }}
    - unless: ls touch {{ location }}/{{ file_name }}.unpacked
    - require:
        - grid-download-{{ file_name }}

  {% endfor %}

{% endif %}
