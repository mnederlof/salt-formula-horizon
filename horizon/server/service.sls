{%- from "horizon/map.jinja" import server with context %}
{%- if server.enabled %}

horizon_packages:
  pkg.installed:
  - names: {{ server.pkgs }}

horizon_apache_package_absent:
  pkg.purged:
  - name: openstack-dashboard-apache
  - require:
    - pkg: horizon_packages
  - watch_in:
    - service: horizon_services

horizon_config:
  file.managed:
  - name: {{ server.config }}
  - source: salt://horizon/files/local_settings/{{ server.version }}_settings.py
  - template: jinja
  - mode: 640
  - user: root
  - group: horizon
  - require:
    - pkg: horizon_packages

horizon_apache_port_config:
  file.managed:
  - name: {{ server.port_config_file }}
  - source: {{ server.port_config_template }}
  - template: jinja
  - mode: 644
  - user: root
  - group: root
  - require_in:
    - service: horizon_services
  - require:
    - pkg: horizon_packages

horizon_apache_config:
  file.managed:
  - name: {{ server.apache_config }}
  - source: salt://horizon/files/openstack-dashboard.conf.{{ grains.os_family }}
  - template: jinja
  - mode: 644
  - user: root
  - group: root
  - require:
    - pkg: horizon_packages

{%- if grains.os_family == 'Debian' %}
apache_enable_wsgi:
  apache_module.enable:
    - name: wsgi

enable_horizon_apache_config:
  apache_conf.enable:
  - name: openstack-dashboard
  - require:
    - file: horizon_apache_config
    - apache_module: apache_enable_wsgi
{%- endif %}

horizon_services:
  service.running:
  - name: {{ server.service }}
  - enable: true
  - watch:
    - file: horizon_config
    - file: horizon_apache_config
    - file: horizon_log_file

horizon_log_dir:
  file.directory:
    - name: /var/log/horizon
    - user: horizon
    - group: adm
    - mode: 750

horizon_log_file:
  file.managed:
    - name: /var/log/horizon/horizon.log
    - user: horizon
    - group: adm
    - mode: 640
    - require:
      - file: horizon_log_dir

/etc/logrotate.d/horizon:
  file.managed:
  - source: salt://horizon/files/horizon_logrotate.conf
  - user: root
  - group: root
  - mode: 644

{%- if grains.get('virtual_subtype', None) == "Docker" %}

horizon_entrypoint:
  file.managed:
  - name: /entrypoint.sh
  - template: jinja
  - source: salt://horizon/files/entrypoint.sh
  - mode: 755

{%- endif %}

{%- endif %}
