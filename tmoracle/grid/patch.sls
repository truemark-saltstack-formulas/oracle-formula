{% if pillar['tmoracle']['grid'] is defined %} # start if grid

{% set oracle_base = salt['pillar.get']('tmoracle:oracle_base') %}
{% set home = oracle_base + '/product/' + salt['pillar.get']('tmoracle:grid:home') %}

########
# OPatch
########
{% if pillar['tmoracle']['grid']['opatch'] is defined %}

{% set opatch_file_name = salt['pillar.get']('tmoracle:grid:opatch:file_name') %}
{% set opatch_url = salt['pillar.get']('tmoracle:grid:opatch:url') %}

grid-tmoracle-opatchdir:
  file.directory:
    - name: {{ home }}/.tmoracle/opatch
    - makedirs: True
    - user: oracle
    - group: oinstall
    - momde: 0755

# Download OPatch Files
'grid-opatch-download-{{ opatch_file_name }}':
  cmd.run:
    - name: curl -s -f {{ opatch_url }} --output {{ home }}/.tmoracle/opatch/{{ opatch_file_name }}
    - unless: ls {{ home }}/.tmoracle/opatch/{{ opatch_file_name }}.installed
    - require:
      - 'grid-tmoracle-opatchdir'

'grid-opatch-unpack-{{ opatch_file_name }}':
  cmd.run:
    - name: 'su -c "cd {{ home }}; unzip -qq -o {{ home }}/.tmoracle/opatch/{{ opatch_file_name }}" oracle'
    - onchanges:
      - 'grid-opatch-download-{{ opatch_file_name }}'

'grid-opatch-rm-{{ opatch_file_name }}':
  cmd.run:
    - name: rm {{ home }}/.tmoracle/opatch/{{ opatch_file_name }} && touch {{ home }}/.tmoracle/opatch/{{ opatch_file_name }}.installed
    - onchanges:
      - 'grid-opatch-unpack-{{ opatch_file_name }}'

{% endif %}


################################
# Cumulative Patch Updates (CPU)
################################
{% if pillar['tmoracle']['grid']['cpu'] is defined %}

{% set cpu_id = salt['pillar.get']('tmoracle:grid:cpu:id') %}
{% set cpu_files = salt['pillar.get']('tmoracle:grid:cpu:files', {}) %}

grid-tmoracle-patchdir:
  file.directory:
    - name: {{ home }}/.tmoracle/patches
    - makedirs: True
    - user: oracle
    - group: oinstall
    - mode: 0755

# Download Patch Files
{% for cpu_file_name, cpu_url in cpu_files.items() %}
grid-cpu-download-{{ cpu_file_name }}:
  cmd.run:
    - name: curl -s -f {{ cpu_url }} --output {{ home }}/.tmoracle/patches/{{ cpu_file_name }}
    - unless: ls {{ home }}/.tmoracle/patches/{{ cpu_id }}
    - require:
      - grid-tmoracle-patchdir
{% endfor %}


# Unpack & Delete Patch Files
{% for cpu_file_name, cpu_url in cpu_files.items() %}
grid-cpu-unpack-{{ cpu_file_name }}:
  cmd.run:
    - name: su -c "unzip -qq -o {{ cpu_file_name }}" oracle
    - cwd: {{ home }}/.tmoracle/patches
    - onlyif: ls {{ home }}/.tmoracle/patches/{{ cpu_file_name }}
    - require:
      - grid-cpu-download-{{ cpu_file_name }}

grid-cpu-delete-{{ cpu_file_name }}:
  cmd.run:
    - name: rm -f {{ home }}/.tmoracle/patches/{{ cpu_file_name }}
    - onlyif: ls {{ home }}/.tmoracle/patches/{{ cpu_file_name }}
    - require:
      - grid-cpu-unpack-{{ cpu_file_name }}
{% endfor %}

###########
# Apply CPU
###########

{% set cpu_patches = salt['pillar.get']('tmoracle:grid:cpu:patches') %}

{% set last_cpu_patch = none %}
{% for cpu_patch in cpu_patches %}

grid-cpu-{{ cpu_id }}-patch-{{ cpu_patch }}-apply:
  cmd.run:
    - name: {{ home }}/OPatch/opatchauto apply {{ home }}/.tmoracle/patches/{{ cpu_id }}/{{ cpu_patch }} -oh {{ home }}
    - unless: 'if [ -f {{ home }}/.tmoracle/patches/{{ cpu_id }}/{{ cpu_patch }} ]; then exit 0; else exit 1; fi'
    {% if last_cpu_patch is not none %}
    - require:
      - grid-cpu-{{ cpu_id }}-patch-{{ last_cpu_patch }}-apply
    {% endif %}

grid-cpu-{{ cpu_id }}-patch-{{ cpu_patch }}-applied:
  cmd.run:
    - name: rm -rf '{{ home }}/.tmoracle/patches/{{ cpu_id }}/{{ cpu_patch }}' && touch {{ home }}/.tmoracle/patches/{{ cpu_id }}/{{ cpu_patch }}
    - unless: 'if [ -f {{ home }}/.tmoracle/patches/{{ cpu_id }}/{{ cpu_patch }} ]; then exit 0; else exit 1; fi'
    - require:
      - grid-cpu-{{ cpu_id }}-patch-{{ cpu_patch }}-apply

{% set last_cpu_patch = cpu_patch %}

{% endfor %}

{% endif %} # end if cpu

{% endif %} # end if grid
