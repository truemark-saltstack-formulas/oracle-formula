{% for name in salt['pillar.get']('tmoracle:software', {}).items() %}
software-{{ name }}:
  cmd.run:
    - name: echo moo
{% endfor %}
