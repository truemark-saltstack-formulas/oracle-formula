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

'systemctl daemon-reload':
  cmd.run:
    - onlyif:
      - Update Salt Minion NOFILE Limit
      - Update Salt Minion NOPROC Limit

Restart Salt Minion:
  cmd.run:
    - name: 'salt-call service.restart salt-minion'
    - bg: True
    - onlyif:
      - systemctl daemon-reload
