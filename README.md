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
      server_names: me.myself.i
      #basedir: /var/www/baikal
      #default_server: False
      #wwwuser: apache
      #wwwgroup: apache
      admin_password: Insecure
      baikal_encryption_key: ALeiseewoh4uo1iem6eiZoathoo5ieRa # pwgen 32
      dbname: baikal
      dbuser: baikal
      dbpass: Insecure
      auth_realm: My Calendar
```

## Delete baikaldav instances

* Define `nuke: True` in your pillar for any defined instance you want to nuke.
* run `salt-ssh my.host.name state.apply baikaldav.nuke`

## Reset admin password

Change admin password value in your pillar and re-run the `baikaldav`-state with salt.

