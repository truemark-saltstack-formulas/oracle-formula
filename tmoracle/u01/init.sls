{% if pillar['tmoracle']['u01'] is defined %}

u01-mkfs:
  blockdev.formatted:
    - name: {{ pillar['tmoracle']['u01'] }}
    - fs_type: ext4
    - force: True
u01-mount:
  mount.mounted:
    - name: /u01
    - device: {{ pillar['tmoracle']['u01'] }}
    - fstype: ext4
    - dump: 1
    - pass_num: 2
    - opts: noatime
    - mkmnt: True
    - persist: True
    - require:
      - u01-mkfs

{% endif %}
