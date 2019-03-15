{% if pillar['tmoracle']['software'] is defined %}

  {% set location = salt['pillar.get']('tmoracle:software:location') %}

software-location:
  file.directory:
    - name: {{ location }}
    - makedirs: True
    - user: oracle
    - group: oinstall
    - mode: 755

  {% for download in salt['pillar.get']('tmoracle:software:downloads') %}

software-location-{{ download }}:
  file.directory:
    - name: {{ location }}/{{ download }}
    - makedirs: True
    - user: oracle
    - group: oinstall
    - mode: 0755

    {% for file_name, file_url in salt['pillar.get']('tmoracle:software:downloads:' + download + ':files', {}).items() %}


software-download-{{ file_name }}:
  cmd.run:
    - name: curl -C - {{ file_url }} --output {{ location }}/{{ download }}/{{ file_name }}
    - unless: ls {{ location }}/{{ download }}/{{ file_name }}.unpacked
    - require:
        - software-location

software-unpack-{{ file_name }}:
  cmd.run:
    - name: su -c "unzip -o {{ file_name }}" oracle && touch {{ location }}/{{ download }}/{{ file_name }}.unpacked
    - cwd: {{ location }}/{{ download }}
    - unless: ls {{ location }}/{{ download }}/{{ file_name }}.unpacked
    - require:
        - software-download-{{ file_name }}

software-delete-{{ file_name }}:
  cmd.run:
    - name: rm {{ location }}/{{ download }}/{{ file_name }}
    - cwd: {{ location }}/{{ download }}
    - onlyif: ls {{ location }}/{{ download }}/{{ file_name }}
    - require:
        - software-unpack-{{ file_name }}

    {% endfor %}

  {% endfor %}

{% endif %}
