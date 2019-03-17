{% set oracle_host = salt['grains.get']('host') %}
{% set oracle_inventory = salt['pillar.get']('tmoracle:oracle_inventory') %}
{% set oracle_base = salt['pillar.get']('tmoracle:oracle_base') %}
{% set download_location = salt['pillar.get']('tmoracle:download_location') %}

# Create the oracle base directories
'oracle_base':
  file.directory:
    - name: {{ oracle_base }}
    - makedirs: True
    - user: oracle
    - group: oinstall
    - mode: 0755

{% for home in salt['pillar.get']('tmoracle:homes') %}

{% set software = salt['pillar.get']('tmoracle:homes:' + home + ':software') %}
{% set software_location = download_location + '/' + software %}
{% set oracle_home = oracle_base + '/product/' + home %}
{% set oracle_edition = salt['pillar.get']('tmoracle:homes:' + home + ':edition') %}
{% set rsp = salt['pillar.get']('tmoracle:homes:' + home + ':rsp') %}

# Create the oracle home directory
'{{ oracle_home }}':
  file.directory:
    - makedirs: True
    - user: oracle
    - group: oinstall
    - mode: 0755
    - require:
      - oracle_base

# Create the silent install file
'{{ oracle_home }}.rsp':
  file.managed:
    - source: {{ rsp }}
    - user: oracle
    - group: oinstall
    - mode: 0644
    - template: jinja
    - context:
        oracle_host: {{ oracle_host }}
        oracle_inventory: {{ oracle_inventory }}
        oracle_base: {{ oracle_base }}
        oracle_home: {{ oracle_home }}
        oracle_edition: {{ oracle_edition }}
    - require:
      - '{{ oracle_home }}'

'install-{{ oracle_home }}':
  cmd.run:
    - name: {{ software_location }}/database/runInstaller -silent -responseFile {{ oracle_home }}.rsp
    - runas: oracle
    - require:
      - '{{ oracle_home }}.rsp'

#'{{ pillar.tmoracle.oracle_base }}/{{ home }}':

  {%- do salt.log.debug('MOO') -%}
  {%- do salt.log.debug(software_location) -%}


{% endfor %}
