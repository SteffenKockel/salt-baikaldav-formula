# salt-baikaldav-formula

Automatic Install for baikaldav with salt

## Tested with

* CentOS6
* PHP56
* epel-repo enabled
* webtatic-repo enabled

## server side ependencies

* MariaDB or Mysql
* python-mysql bindings 
* wget
* nginx

## define Baikal instances

from `pillar.example`. Lines starting with `#` are not needed, but configurable for each instance.

```
baikal:
  baikal_instances:
    customername:
      #default_server: False
      #nuke: False
      #basedir: /var/www/baikal
      #wwwuser: apache
      #wwwgroup: apache
      #version: 0.4.6 # used as tag to checkout!
      #port: 80
      #ssl_enabled: False
      #sslcert: 
      #sslkey:
      #source_url: https://github.com/fruux/Baikal.git
      #template: salt://baikaldav/etc/nginx/conf.d/baikaldav.conf
      server_names: my.server.name
      admin_password: Insecure
      baikal_encryption_key: ALeiseewoh4uo1iem6eiZoathoo5ieRa # pwgen 32
      auth_realm: {{ grains['fqdn'] }}
      dbhost: 127.0.0.1
      dbname: baikal
      dbuser: baikal
      dbpass: Hallo123
```

## Delete baikaldav instances

* Define `nuke: True` in your pillar for any defined instance you want to nuke.
* run `salt-ssh my.host.name state.apply baikaldav.nuke`

## Reset admin password

Change admin password value in your pillar and re-run the `baikaldav`-state with salt.

