{% set oracle_inventory = salt['pillar.get']('tmoracle:oracle_inventory') %}
{% set oracle_base = salt['pillar.get']('tmoracle:oracle_base') %}
{% set oracle_host = salt['grains.get']('host') %}

{% for home in salt['pillar.get']('tmoracle:homes') %} # start for home

{% set oracle_home = oracle_base + '/product/' + home %}
{% set download_location =  oracle_home + '-downloads' %}
{% set oracle_edition = salt['pillar.get']('tmoracle:homes:' + home + ':edition') %}
{% set rsp = salt['pillar.get']('tmoracle:homes:' + home + ':rsp') %}
{% set software = salt['pillar.get']('tmoracle:homes:' + home + ':software') %}
{% set software_files = salt['pillar.get']('tmoracle:software:' + software + ':files', {}) %}

################################
# Download Software
################################
'{{ download_location }}':
  file.directory:
    - makedirs: True
    - user: oracle
    - group: oinstall
    - mode: 0755
    - unless:
      - ls {{ oracle_home }}/bin/sqlplus

'{{ download_location }}/runInstallerWrapper.sh':
  file.managed:
    - source: salt://tmoracle/homes/files/runInstallerWrapper.sh
    - user: oracle
    - group: oinstall
    - mode: 0740
    - require:
      - '{{ download_location }}'
    - unless:
      - ls {{ oracle_home }}/bin/sqlplus

# Download Software Files
{% for file_name, file_url in software_files.items() %}
'{{ download_location}}/{{ file_name }}-download':
  cmd.run:
    - name: curl -s -f {{ file_url }} --output {{ download_location }}/{{ file_name }}
    - unless: ls {{ download_location }}/database
    - require:
      - '{{ download_location }}'
    - unless:
      - ls {{ oracle_home }}/bin/sqlplus
{% endfor %}

# Unpack & Delete Software Files
{% for file_name, file_url in software_files.items() %}
'{{ download_location}}/{{ file_name }}-unpack':
  cmd.run:
    - name: su -c "cd {{ download_location }}; unzip -qq -o {{ file_name }}" oracle
    - onlyif: ls {{ download_location }}/{{ file_name }}
    - require:
      - '{{ download_location}}/{{ file_name }}-download'

'{{ download_location}}/{{ file_name }}-delete':
  cmd.run:
    - name: rm -f {{ download_location }}/{{ file_name }}
    - onlyif: ls {{ download_location }}/{{ file_name }}
    - require:
      - '{{ download_location}}/{{ file_name }}-unpack'
{% endfor %}

################################
# Setup Home
################################

# Create the oracle home directory
'{{ oracle_home }}':
  file.directory:
    - makedirs: True
    - user: oracle
    - group: oinstall
    - mode: 0755

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
      - '{{ download_location }}/runInstallerWrapper.sh'

'{{ oracle_home }}-install':
  cmd.run:
    - name: {{ download_location }}/runInstallerWrapper.sh {{ download_location }}/database/runInstaller {{ oracle_home }}.rsp
    - runas: oracle
    - unless:
      - ls {{ oracle_home }}/bin/sqlplus
    - require:
      - '{{ oracle_home }}.rsp'

'{{ oracle_home }}-orainstRoot.sh':
  cmd.run:
    - name: {{ oracle_inventory }}/orainstRoot.sh
    - onchanges:
      -  '{{ oracle_home }}-install'

'{{ oracle_home }}-root.sh':
  cmd.run:
    - name: {{ oracle_home }}/root.sh
    - onchanges:
      - '{{ oracle_home }}-install'

'{{ download_location }}-delete':
  cmd.run:
    - name: rm -rf {{ download_location }}
    - onlyif:
      - ls {{ oracle_home }}/bin/sqlplus
      - ls {{ download_location }}

{% endfor %} # end for home
