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

oracle-asm-create-disk:
  cmd.run:
    - name: 'oracleasm createdisk DATA1 /dev/sdc1'
    - unless: oracleasm querydisk DATA1
    - require:
        - oracle-asm-init
