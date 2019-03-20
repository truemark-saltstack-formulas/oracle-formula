{% if pillar['tmoracle']['software'] is defined %}

{% set location = salt['pillar.get']('tmoracle:download_location') %}

{% for software in salt['pillar.get']('tmoracle:software') %} # start for software

##########
# Software
##########

{% set software_files = salt['pillar.get']('tmoracle:software:' + software + ':files', {}) %}

software-location-{{ software }}:
  file.directory:
    - name: {{ location }}/{{ software }}
    - makedirs: True
    - user: oracle
    - group: oinstall
    - mode: 0755

software-location-{{ software }}-patches:
  file.directory:
    - name: {{ location }}/{{ software }}/patches
    - makedirs: True
    - user: oracle
    - group: oinstall
    - mode: 0755

# Download Software Files
{% for file_name, file_url in software_files.items() %}
software-download-{{ file_name }}:
  cmd.run:
    - name: curl -s -f {{ file_url }} --output {{ location }}/{{ software }}/{{ file_name }}
    - unless: ls {{ location }}/{{ software }}/database
    - require:
      - software-location-{{ software }}
{% endfor %}

# Unpack & Delete Software Files
{% for file_name, file_url in software_files.items() %}
software-unpack-{{ file_name }}:
  cmd.run:
    - name: su -c "unzip -qq -o {{ file_name }}" oracle
    - cwd: {{ location }}/{{ software }}
    - onlyif: ls {{ location }}/{{ software }}/{{ file_name }}
    - require:
      - software-download-{{ file_name }}
software-delete-{{ file_name }}:
  cmd.run:
    - name: rm -f {{ location }}/{{ software }}/{{ file_name }}
    - onlyif: ls {{ location }}/{{ software }}/{{ file_name }}
    - require:
      - software-unpack-{{ file_name }}
{% endfor %}

################################
# Cumulative Patch Updates (CPU)
################################
{% if pillar['tmoracle']['software'][software]['cpu'] is defined %}

{% set cpu_id = salt['pillar.get']('tmoracle:software:' + software + ':cpu:id') %}
{% set cpu_files = salt['pillar.get']('tmoracle:software:' + software + ':cpu:files', {}) %}

# Download Patch Files
{% for cpu_file_name, cpu_url in cpu_files.items() %}

software-{{ software }}-cpu-download-{{ cpu_file_name }}:
  cmd.run:
    - name: curl -s -f {{ cpu_url }} --output {{ location }}/{{ software }}/patches/{{ cpu_file_name }}
    - unless: ls {{ location }}/{{ software }}/patches/{{ cpu_id }}
    - require:
      - software-location-{{ software }}-patches

{% endfor %}

# Unpack & Delete Patch Files
{% for cpu_file_name, cpu_url in cpu_files.items() %}

software-{{ software }}-cpu-unpack-{{ cpu_file_name }}:
  cmd.run:
    - name: su -c "unzip -qq -o {{ cpu_file_name }}" oracle
    - cwd: '{{ location }}/{{ software }}/patches'
    - onlyif: ls {{ location }}/{{ software }}/patches/{{ cpu_file_name }}
    - require:
      - software-{{ software }}-cpu-download-{{ cpu_file_name }}

software-{{ software }}-cpu-delete-{{ cpu_file_name }}:
  cmd.run:
    - name: rm -f {{ location }}/{{ software }}/patches/{{ cpu_file_name }}
    - onlyif: ls {{ location }}/{{ software }}/patches/{{ cpu_file_name }}
    - require:
      - software-{{ software }}-cpu-unpack-{{ cpu_file_name }}

{% endfor %}

{% endif %}

########
# OPatch
########

{% if pillar['tmoracle']['software'][software]['opatch'] is defined %}

{% set opatch_file_name = salt['pillar.get']('tmoracle:software:' + software + ':opatch:file_name') %}
{% set opatch_url = salt['pillar.get']('tmoracle:software:' + software + ':opatch:url') %}

# Download OPatch Files
software-{{ software }}-opatch-download-{{ opatch_file_name }}:
  cmd.run:
    - name: curl -s -f {{ opatch_url }} --output {{ location }}/{{ software }}/patches/{{ opatch_file_name }}
    - unless: ls '{{ location }}/{{ software }}/patches/{{ opatch_file_name }}'
    - require:
      - software-location-{{ software }}-patches

{% endif %}

{% endfor %} # end for software

{% endif %}

