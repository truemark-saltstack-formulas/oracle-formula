{% if pillar['tmoracle']['u01'] is defined %}

u01-mkfs:
  blockdev.formatted:
    - name: /dev/sdb
    - fs_type: ext4
    - force: True
u01-mount:
  mount.mounted:
    - name: /u01
    - device: /dev/sdb
    - fstype: ext4
    - dump: 1
    - pass_num: 2
    - opts: noatime
    - mkmnt: True
    - persist: True
    - require:
      - u01-mkfs

{% endif %}
