Nginx Metrix
============

Nginx metrics written on lua and works with nginx-lua-module

Usage
-----

Put into `http` section

```
include /etc/nginx/metrics/http.conf;
```

Put into `server` section

```
include /etc/nginx/metrics/counter.conf;
include /etc/nginx/metrics/metrics-default-location.conf;
```

Unit Tests
----------

`/usr/local/bin/busted -c -v -o utfTerminal -- tests`

TODO
----

- [ ] Travis-CI (https://github.com/moteus/lua-travis-example)
- [ ] Coveralls (https://github.com/moteus/luacov-coveralls) `luacov-coveralls -v --dryrun -i './metrix/*'`
