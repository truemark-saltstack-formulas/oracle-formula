oracle-asm-update:
  file.managed:
    - name: /etc/sysconfig/oracleasm-_dev_oracleasm
    - source: {{ 'salt://tmoracle/asm/files/oracleasm-_dev_oracleasm.jinja' }}
    - template: jinja
    - user: root
    - group: root
    - mode: 644

oracle-asm-init:
  cmd.run:
    - name: oracleasm init
    - unless: oracleasm status
    - require:
        - oracle-asm-update

{% for name, device in salt['pillar.get']('tmoracle:asm:disks', {}).items() %}

oracle-asm-partition-disk-{{ name }}:
  cmd.run:
    - name: parted -s {{ device }} mklabel gpt && parted -a optimal {{ device }} mkpart primary 0% 100%
    - unless: oracleasm querydisk {{ name }} {{ device }}
    - require:
        - oracle-asm-init

oracle-asm-create-disk-{{ name }}:
  cmd.run:
    - name: oracleasm createdisk {{ name }} {{ device }}1
    - unless: oracleasm querydisk {{ name }} {{ device }}1
    - require:
        - oracle-asm-partition-disk-{{ name }}

{% endfor %}
