start-grid:
  cmd.run:
    - name: su -c "{{ pillar.tmoracle.oracle_base }}/product/{{ pillar.tmoracle.grid.home }}/bin/crsctl start has" - oracle
