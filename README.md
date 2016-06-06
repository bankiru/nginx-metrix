Nginx Metrix
============
[![Travis CI Build Status](https://travis-ci.org/bankiru/nginx-metrix.svg?branch=1.0-dev)](https://travis-ci.org/bankiru/nginx-metrix)
[![Appveyor Build Status](https://ci.appveyor.com/api/projects/status/s3hy8fq32869o375/branch/1.0-dev?svg=true)](https://ci.appveyor.com/project/ekho/nginx-metrix/branch/1.0-dev)
[![Coverage Status](https://coveralls.io/repos/github/bankiru/nginx-metrix/badge.svg?branch=1.0-dev)](https://coveralls.io/github/bankiru/nginx-metrix?branch=1.0-dev)

Extended nginx status and metrics.

Description
-----------

Nginx out-of-the-box has not the most complete status page provided by [status](http://nginx.org/ru/docs/http/ngx_http_status_module.html) module.
It is worth noting that in Nginx Plus, this module provides more information.

But using [lua](https://github.com/openresty/lua-nginx-module) module can get much more information. This is the purpose nginx-metrix.

Metrix entirely written in [lua](https://www.lua.org/).

**Base features of Metrix:**
* OpenSource ([MIT licence](https://github.com/bankiru/nginx-metrix/blob/master/LICENCE))
* modularity
* extensibility (in future)
* complete code coverage

Requirements
------------

* nginx >= 1.6.0, but recommended >= 1.9.0
* lua-nginx-module >= 0.9.17
* luarocks >= 2.0

Usage
-----

Nginx with lua-nginx-module should be installed using their instructions.

### Install nginx metrix module

```
luarocks install nginx-metrix
```

### Configure nginx

Put into `http` section

```
lua_shared_dict metrix 128m;

lua_package_path '/etc/nginx/?.lua;;';
lua_package_cpath '/etc/nginx/?.so;;';

init_by_lua_block {
    metrix = require 'nginx-metrix.main'({
        shared_dict = 'metrix',
        vhosts = {[[mydomain1]], [[mydomain2]], ...}
    })
}

init_worker_by_lua_block {
    metrix.init_scheduler()
}
```

Put into every `server` section

```
log_by_lua_block {
    metrix.handle_ngx_phase()
}
```

To collect stats you should add special location to existing or separate `server` section.

Location for existing `server`s:
```
location /metrix/ {
    default_type 'text/plain';
    content_by_lua_block {
        metrix.show()
    }
}
```

Separate `server`:

```
server {
    listen 81;
    server_name metrix;

    location / {
        default_type 'text/plain';
        content_by_lua_block {
            metrix.show({vhosts_filter='.*'})
        }
    }
}
```

### See or collect stats

You can see stats in `text`, `html` and `json` formats.

Format determines by `Accept` http header or by parameter `format`.

If you are using existing `server` with special location you will see stats about this vhost.
If you are using separate `server` stats for all existing (collected) vhosts will be showed.
If you want to see stats about only one you should pass parameter `vhost=yourdomain.com`

Extending
---------

TODO: write how to extend metrix


Contributing
------------

See CONTRIBUTING.md. All issues, suggestions, and most importantly pull requests are welcome.

Testing
-------

Run `busted` (http://olivinelabs.com/busted/)

Licence
-------

Copyright 2016 Banki.ru News Agency, Ltd. MIT licensed. See LICENSE for details.
