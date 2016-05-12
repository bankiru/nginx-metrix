Nginx Metrix
============

Nginx metrics written on lua and works on top of nginx-lua-module

Usage
-----

Put into `http` section

```
include /etc/nginx/metrix/http.conf;
```

Put into `server` section

```
include /etc/nginx/metrix/counter.conf;
include /etc/nginx/metrix/metrics-default-location.conf;
```

Unit Tests
----------

Run `busted` (http://olivinelabs.com/busted/)

TODO
----

- [ ] Travis-CI (https://github.com/moteus/lua-travis-example)
- [ ] Coveralls (https://github.com/moteus/luacov-coveralls) `luacov-coveralls -v --dryrun -i './metrix/*'`
