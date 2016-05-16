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

Contributing
------------

See CONTRIBUTING.md. All issues, suggestions, and most importantly pull requests are welcome.

Unit Tests
----------

Run `busted` (http://olivinelabs.com/busted/)

Licence
-------

Copyright 2016 Banki.ru News Agency, Ltd. MIT licensed. See LICENSE for details.
