{% from 'baikaldav/map.jinja' import baikal with context %}
{% set spg = salt['pillar.get'] %}

install_php_packages:
  pkg.installed:
    - pkgs: {{baikal.packages}}

{% set idefs = baikal.baikal_instance_defaults %}
# Install multiple baikal instances
{% for k,v in pillar.baikal.baikal_instances.iteritems() %}
## Merge instance defaults and instance declaration
{% set iconfig = {} %}
{% do iconfig.update(idefs) %}
{% do iconfig.update(v) %}
{% do iconfig.update({ 'fulldir': iconfig.basedir+'/'+k, 'id': k }) %}

## Check, if Dirs exist
makedirs_baikal_repo_{{k}}:
  file.directory:
    - name: {{iconfig.fulldir}}
    - user: root
    - group: root
    - mode: 755

## Clone the repo
clone_baikal_repo_{{k}}:
  git.latest:
    - name: {{iconfig.source_url}}
    - rev: {{iconfig.version}}
    - force_reset: False
    - force_fetch: False
    - force_clone: False
    - target: {{iconfig.fulldir}}

## Setup baikal
{{iconfig.fulldir}}/Specific/config.php:
  file.managed:
    - template: jinja
    - source: salt://baikaldav/files/baikal/config.php
    - user: {{iconfig.wwwuser}}
    - group: {{iconfig.wwwgroup}}
    - context:
      iconfig: {{iconfig}}

## Setup baikal
{{iconfig.fulldir}}/Specific/config.system.php:
  file.managed:
    - template: jinja
    - source: salt://baikaldav/files/baikal/config.system.php
    - user: {{iconfig.wwwuser}}
    - group: {{iconfig.wwwgroup}}
    - context:
      iconfig: {{iconfig}}

{{iconfig.fulldir}}/Specific/INSTALL_DISABLED:
  file.touch

## Install composer and setup databases
install_composer_{{k}}:
  cmd.run:
    - cwd: {{iconfig.fulldir}}
    - names:      
      - php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
      - php -r "if (hash_file('SHA384', 'composer-setup.php') === '669656bab3166a7aff8a7506b8cb2d1c292f042046c5a994c43155c0be6190fa0355160742ab2e1c88d40d5be660b410') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
      - php composer-setup.php
      - php -r "unlink('composer-setup.php');"
    - unless:
      - test -f {{iconfig.fulldir}}/composer.phar

#
# Fixme: fails on firstrun due to non-reloaded webserver
#

run_composer_{{k}}:
  cmd.run:
    - cwd: {{iconfig.fulldir}}
    - names:
      - {{iconfig.fulldir}}/composer.phar install

#install_mariadb_tables_{{k}}:
#  cmd.run:
#    - names:
#      - mysql -u root -p{{pillar.mysql.root_pw}} -e "CREATE DATABASE IF NOT EXISTS {{iconfig.dbname}};"
#      - mysql -u root -p{{pillar.mysql.root_pw}} -e "GRANT ALL PRIVILEGES ON {{iconfig.dbname}}.* TO {{iconfig.dbuser}}@localhost IDENTIFIED BY '{{iconfig.dbpass}}'"
#      - cat {{iconfig.fulldir}}/vendor/sabre/dav/examples/sql/mysql.* | mysql -u root -p{{pillar.mysql.root_pw}} {{iconfig.dbname}}

install mysql database {{k}}:
  mysql_database.present:
    - name: {{iconfig.dbname}}
    - connection_user: root
    - connection_pass: {{pillar.mysql.root_pw}}
    - connection_charset: utf8
    - connection_unix_socket: /var/run/mysqld/mysqld.sock

install_mysql_user_{{k}}:
  mysql_user.present:
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
  mysql_grants.present:
    - grant: ALL
    - database: {{iconfig.dbname}}.*
    - user: {{iconfig.dbuser}}
    - host: localhost
    - connection_user: root
    - connection_pass: {{pillar.mysql.root_pw}}
    - connection_charset: utf8
    - connection_unix_socket: /var/run/mysqld/mysqld.sock

# Concat tables into one file
join_tables_{{k}}:
  cmd.run:
    - names:
      - cat {{iconfig.fulldir}}/vendor/sabre/dav/examples/sql/mysql.* > /tmp/{{k}}.sql
    - unless:
      - test -f /tmp/{{k}}.sql

install_mysql_tables_{{k}}:
  mysql_query.run_file:
    - database: {{iconfig.dbname}}
    - query_file: /tmp/{{k}}.sql
    - connection_user: root
    - connection_pass: {{pillar.mysql.root_pw}}
    - connection_charset: utf8
    - connection_unix_socket: /var/run/mysqld/mysqld.sock
    - require: 
      - join_tables_{{k}}

# Reload server
#

{{baikal.server}}_restart_{{k}}:
  service.running:
    - name: {{baikal.server}}
    #- reload: True
    - enable: True
    - sig: /usr/sbin/nginx


#
# run the webinstaller
# 
activate_baikal_{{k}}:
  cmd.run:
    - names:
      {% if iconfig.ssl_enabled == True %}
      - wget -qO- --no-check-certificate https://{{iconfig.server_names}}
      {% else %}
      - wget -qO http://{{iconfig.server_names}}
      {% endif%}






## setup vhost

/etc/nginx/conf.d/baikal_{{k}}.conf:
  file.managed:
    - template: jinja
    - source: salt://baikaldav/files/etc/nginx/conf.d/baikaldav.conf
    - context: 
      instance: {{v}}
      instance_id: {{k}}
      iconfig: {{iconfig}}
      config: {{baikal}}




{% endfor %}

