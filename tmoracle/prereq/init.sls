oracle-prereqs:
  pkg.installed:
    - pkgs:
      - oracle-database-server-12cR2-preinstall
      - oracleasm-support

oracle-asm-update:
  file.managed:
    - name: /etc/sysconfig/oracleasm-_dev_oracleasm
    - source: {{ 'salt://tmoracle/prereq/files/oracleasm-_dev_oracleasm' }}
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: oracle-prereqs

