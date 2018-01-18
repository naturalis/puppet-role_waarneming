puppet-role_waarneming
===================

Puppet role definition for deployment of waarneming web and database server

Parameters
-------------
Sensible defaults for Naturalis in init.pp

```

```


Classes
-------------
- role_waarneming::common
- role_waarneming::conf
- role_waarneming::db
- role_waarneming::db_slave
- role_waarneming::django_app
- role_waarneming::mail
- role_waarneming::pgbouncer
- role_waarneming::php_app
- role_waarneming::phppgadmin
- role_waarneming::sites
- role_waarneming::vhost
- role_waarneming::web



Dependencies
-------------
- puppetlabs/postgres
- puppetlabs/concat
- voxpupuli/php
- voxpupuli/nginx
- voxpupuli/memcached



Puppet code
```
class { role_waarneming: }
```
Result
-------------
Working waarneming.nl site including db_slave and phppgadmin


Limitations
-------------
This module has been built on and tested against Puppet 4 and higher.

The module has been tested on:
- Ubuntu 16.04LTS

Dependencies releases tested: 
- puppetlabs/concat 1.2.0
- voxpupuli/php




Authors
-------------
Author Name <hugo.vanduijn@naturalis.nl>

