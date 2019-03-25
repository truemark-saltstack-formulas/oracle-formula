{% if pillar['tmoracle']['grid'] is defined %} # start if grid

include:
  - tmoracle.grid.setup
  - tmoracle.grid.patch

{% endif %} # end if grid
