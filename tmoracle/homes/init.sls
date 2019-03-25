{% if pillar['tmoracle']['homes'] is defined %} # start if homes

include:
  - tmoracle.homes.setup
  - tmoracle.homes.patch

{% endif %} # end if homes
