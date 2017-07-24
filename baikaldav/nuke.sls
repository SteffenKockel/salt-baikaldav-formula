{% from 'baikaldav/map.jinja' import baikal with context %}
{% set spg = salt['pillar.get'] %}


{% set idefs = baikal.baikal_instance_defaults %}
# Install multiple baikal instances


{% for k,v in pillar.baikal.baikal_instances.iteritems() %}
## Merge instance defaults and instance declaration
{% set iconfig = {} %}
{% do iconfig.update(idefs) %}
{% do iconfig.update(v) %}
{% do iconfig.update({ 'fulldir': iconfig.basedir+'/'+k, 'id': k }) %}


{% if iconfig.nuke == True %}

install mysql database {{k}}:
  mysql_database.absent:
    - name: {{iconfig.dbname}}
    - connection_user: root
    - connection_pass: {{pillar.mysql.root_pw}}
    - connection_charset: utf8
    - connection_unix_socket: /var/run/mysqld/mysqld.sock

install_mysql_user_{{k}}:
  mysql_user.absent:
    - host: localhost
    - name: {{iconfig.dbuser}}
    - password: {{iconfig.dbpass}}
    - connection_user: root
    - connection_pass: {{pillar.mysql.root_pw}}
    - connection_charset: utf8
    - connection_unix_socket: /var/run/mysqld/mysqld.sock
    #- saltenv:
    #  - LC_ALL: "en_US.utf8"

grant_mysql_table_permissions_{{k}}:
  mysql_grants.absent:
    - grant: ALL
    - database: {{iconfig.dbname}}.*
    - user: {{iconfig.dbuser}}
    - host: localhost
    - connection_user: root
    - connection_pass: {{pillar.mysql.root_pw}}
    - connection_charset: utf8
    - connection_unix_socket: /var/run/mysqld/mysqld.sock

## remove vhost

/etc/nginx/conf.d/baikal_{{k}}.conf:
  file.absent

## Delete baikal Dir

## Check, if Dirs exist
rmdir_baikal_repo_{{k}}:
  file.absent:
    - name: {{iconfig.fulldir}}

{% endif %}

{% endfor %}

# Reload server
#

{{baikal.server}}:
  service.running:
    - reload: True
    - enable: True
