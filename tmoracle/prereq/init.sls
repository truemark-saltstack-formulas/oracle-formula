{% set oracle_inventory = salt['pillar.get']('tmoracle:oracle_inventory') %}

'{{ oracle_inventory }}':
  file.directory:
    - makedirs: True
    - user: oracle
    - group: oinstall
    - mode: 0770

Install Oracle Prerequisites:
  pkg.installed:
    - pkgs:
      - oracle-database-server-12cR2-preinstall
      - oracleasm-support
      - gcc
      - gcc-c++
      - nscd
      - bc
      - ksh
      - mksh
      - elfutils-libelf-devel

Setup Oracle Bash:
  file.blockreplace:
    - name: /home/oracle/.bash_profile
    - marker_start: '# SALT START DO NOT EDIT'
    - marker_end: '# SALT END DO NOT EDIT'
    - content: |
        echo
        echo "#############################################################"
        for file in ~/.bashrc.d/*; do source "$file"; done
        echo "#############################################################"
        echo
    - append_if_not_found: True
    - backup: '.bak'

'/home/oracle/.bashrc.d':
  file.directory:
    - user: oracle
    - group: oinstall
    - mode: 0755

Update Salt Minion NOFILE Limit:
  file.line:
    - name: /usr/lib/systemd/system/salt-minion.service
    - mode: replace
    - match: LimitNOFILE
    - content: LimitNOFILE=65536

Update Salt Minion NOPROC Limit:
  file.line:
    - name: /usr/lib/systemd/system/salt-minion.service
    - mode: ensure
    - after: LimitNOFILE
    - before: ExecStart
    - content: LimitNPROC=16384

Update Salt Minion STACK Limit:
  file.line:
    - name: /usr/lib/systemd/system/salt-minion.service
    - mode: ensure
    - after: LimitNPROC
    - before: ExecStart
    - content: LimitSTACK=10240K

'systemctl daemon-reload':
  cmd.run:
    - onchanges_any:
        - Update Salt Minion NOFILE Limit
        - Update Salt Minion NOPROC Limit
        - Update Salt Minion STACK Limit

Restart Salt Minion:
  cmd.run:
    - name: 'salt-call service.restart salt-minion'
    - bg: True
    - onchanges:
      - systemctl daemon-reload
