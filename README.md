Nginx Metrix
============

Nginx metrics written on lua and works on top of nginx-lua-module

Usage
-----

### Install

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
    metrix.handle_ngx_phase('log')
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
