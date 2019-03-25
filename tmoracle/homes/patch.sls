{% for home in salt['pillar.get']('tmoracle:homes') %} # start for home

{% set oracle_base = salt['pillar.get']('tmoracle:oracle_base') %}
{% set oracle_home = oracle_base + '/product/' + home %}
{% set software = salt['pillar.get']('tmoracle:homes:' + home + ':software') %}


########
# OPatch
########
{% if pillar['tmoracle']['software'][software]['opatch'] is defined %} # start if opatch

{% set opatch_file_name = salt['pillar.get']('tmoracle:software:' + software + ':opatch:file_name') %}
{% set opatch_url = salt['pillar.get']('tmoracle:software:' + software + ':opatch:url') %}

'{{ oracle_home }}/.tmoracle/opatch':
  file.directory:
    - makedirs: True
    - user: oracle
    - group: oinstall
    - mode: 0755

'{{ oracle_home }}/.tmoracle/opatch/{{ opatch_file_name }}':
  cmd.run:
    - name: curl -s -f {{ opatch_url }} --output {{ oracle_home }}/.tmoracle/opatch/{{ opatch_file_name }}
    - unless: ls {{ oracle_home }}/.tmoracle/opatch/{{ opatch_file_name }}.installed
    - require:
      - '{{ oracle_home }}/.tmoracle/opatch'

'{{ oracle_home }}/.tmoracle/opatch/{{ opatch_file_name }}-unpack':
  cmd.run:
    - name: 'su -c "cd {{ oracle_home }}; unzip -qq -o {{ oracle_home }}/.tmoracle/opatch/{{ opatch_file_name }}" oracle'
    - onchanges:
      - '{{ oracle_home }}/.tmoracle/opatch/{{ opatch_file_name }}'

'{{ oracle_home }}/.tmoracle/opatch/{{ opatch_file_name }}-delete':
  cmd.run:
    - name: rm {{ oracle_home }}/.tmoracle/opatch/{{ opatch_file_name }} && touch {{ oracle_home }}/.tmoracle/opatch/{{ opatch_file_name }}.installed
    - onchanges:
      - '{{ oracle_home }}/.tmoracle/opatch/{{ opatch_file_name }}'

{% endif %} # end if opatch

#########################################
# Download Cumulative Patch Updates (CPU)
#########################################

{% if pillar['tmoracle']['software'][software]['opatch'] is defined %} # start if cpu

{% set cpu_id = salt['pillar.get']('tmoracle:software:' + software + ':cpu:id') %}
{% set cpu_files = salt['pillar.get']('tmoracle:software:' + software + ':cpu:files', {}) %}

'{{ oracle_home }}/.tmoracle/patches':
  file.directory:
    - makedirs: True
    - user: oracle
    - group: oinstall
    - mode: 0755

# Download Patch Files
{% for cpu_file_name, cpu_url in cpu_files.items() %}
'{{ oracle_home }}/.tmoracle/patches/{{ cpu_file_name }}':
  cmd.run:
    - name: curl -s -f {{ cpu_url }} --output {{ oracle_home }}/.tmoracle/patches/{{ cpu_file_name }}
    - unless: ls {{ oracle_home }}/.tmoracle/patches/{{ cpu_id }}
    - require:
      - '{{ oracle_home }}/.tmoracle/patches'
{% endfor %}

# Unpack & Delete Patch Files
{% for cpu_file_name, cpu_url in cpu_files.items() %}
'{{ oracle_home }}/.tmoracle/patches/{{ cpu_file_name }}-unpack':
  cmd.run:
    - name: su -c "unzip -qq -o {{ cpu_file_name }}" oracle
    - cwd: {{ oracle_home }}/.tmoracle/patches
    - onlyif: ls {{ oracle_home }}/.tmoracle/patches/{{ cpu_file_name }}
    - require:
      - '{{ oracle_home }}/.tmoracle/patches/{{ cpu_file_name }}'

'{{ oracle_home }}/.tmoracle/patches/{{ cpu_file_name }}-delete':
  cmd.run:
    - name: rm -f {{ oracle_home }}/.tmoracle/patches/{{ cpu_file_name }}
    - onlyif: ls {{ oracle_home }}/.tmoracle/patches/{{ cpu_file_name }}
    - require:
      - '{{ oracle_home }}/.tmoracle/patches/{{ cpu_file_name }}'
{% endfor %}

######################################
# Apply Cumulative Patch Updates (CPU)
######################################

'{{ oracle_home }}/OPatch/ocmrsp.expect':
  file.managed:
    - source: salt://tmoracle/homes/files/ocmrsp.expect
    - user: oracle
    - group: oinstall
    - mode: 750
    - unless:
      - ls {{ oracle_home }}/OPatch/opatchauto

'{{ oracle_home }}/OPatch/ocmrsp.expect-exec':
  cmd.run:
    - name: './ocmrsp.expect'
    - cwd: '{{ oracle_home }}/OPatch'
    - asuser: oracle
    - onchanges:
      - '{{ oracle_home }}/OPatch/ocmrsp.expect'

{% set cpu_patches = salt['pillar.get']('tmoracle:software:' + software + ':cpu:patches') %}
{% set last_cpu_patch = none %}
{% for cpu_patch in cpu_patches %}

'{{ oracle_home }}/.tmoracle/patches/{{ cpu_id }}/{{ cpu_patch }}-autoapply':
  cmd.run:
    - name: {{ oracle_home }}/OPatch/opatchauto apply {{ oracle_home }}/.tmoracle/patches/{{ cpu_id }}/{{ cpu_patch }} -oh {{ oracle_home }}
    - unless: 'if [ -f {{ oracle_home }}/.tmoracle/patches/{{ cpu_id }}/{{ cpu_patch }} ]; then exit 0; else exit 1; fi'
    - onlyif:
      - ls {{ oracle_home }}/OPatch/opatchauto
      - if [ -d {{ oracle_home }}/.tmoracle/patches/{{ cpu_id }}/{{ cpu_patch }} ]; then exit 0; else exit 1; fi
    {% if last_cpu_patch is not none %}
    - require:
      - '{{ oracle_home }}/.tmoracle/patches/{{ cpu_id }}/{{ last_cpu_patch }}-autoapply'
    {% endif %}

'{{ oracle_home }}/.tmoracle/patches/{{ cpu_id }}/{{ cpu_patch }}-apply':
  cmd.run:
    - name: ./opatch apply -silent -ocmrf ocm.rsp {{ oracle_home }}/.tmoracle/patches/{{ cpu_id }}/{{ cpu_patch }}
    - cwd: {{ oracle_home }}/OPatch
    - runas: oracle
    - onlyif: if [ -d {{ oracle_home }}/.tmoracle/patches/{{ cpu_id }}/{{ cpu_patch }} ]; then exit 0; else exit 1; fi
    - unless: ls {{ oracle_home }}/OPatch/opatchauto
    {% if last_cpu_patch is not none %}
    - require:
      - '{{ oracle_home }}/.tmoracle/patches/{{ cpu_id }}/{{ last_cpu_patch }}-apply'
    {% endif %}

# TODO This needs to be made more robust to actually onyl run if the patches were applied
'{{ oracle_home }}/.tmoracle/patches/{{ cpu_id }}/{{ cpu_patch }}-applied':
  cmd.run:
    - name: rm -rf '{{ oracle_home }}/.tmoracle/patches/{{ cpu_id }}/{{ cpu_patch }}' && touch {{ oracle_home }}/.tmoracle/patches/{{ cpu_id }}/{{ cpu_patch }}
    - unless: 'if [ -f {{ oracle_home }}/.tmoracle/patches/{{ cpu_id }}/{{ cpu_patch }} ]; then exit 0; else exit 1; fi'

{% endfor %}

{% endif %} # end if cpu

{% endfor %} # end for home
