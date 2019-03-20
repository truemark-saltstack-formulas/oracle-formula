stop-grid:
  cmd.run:
    - name: su -c "{{ pillar.tmoracle.oracle_base }}/product/{{ pillar.tmoracle.grid.home }}/bin/crsctl stop has" - oracle
