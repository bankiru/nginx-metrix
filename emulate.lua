_G.__TEST__ = true

local _m = {
    f = function(self) return 'meta' end
}

_m.__index = _m

local t = {}

t.f = function(self)
    return getmetatable(self).f(self) .. ' -> ' .. 'curr'
end

setmetatable(t, _m)

print(t.f(t))
print(t:f())

--local Lust = require('metrix.lib.Lust')
--
--local temp = Lust{
--    [[
--        @if(c)<c1>else<c2>
--    ]],
--    c1 = "I am a c1",
--    c2 = [[@if(d)<d1>else<d2>]],
--    d1 = "I am a d1",
--    d2 = "I am a d2",
--}
--print(temp:gen{ c=false })

--require('tests.ngx_mock')
--ngx_define_shared_dict('metrix')
--
--local output_tools = require('metrix.output_tools')
--
--print(inspect(output_tools.get_format()))
--
--print(inspect(package.loaded))
--
---- INIT
--metrix = require('metrix.metrix')('metrix')
--
---- CONFIGURE
--metrix.register_collector(require('metrix.collectors.request'))
--metrix.register_collector(require 'metrix.collectors.status')
--metrix.register_collector(require 'metrix.collectors.upstream')
--
---- RUN
--metrix.handle_ngx_phase("log")
--ngx.req.__INTERNAL__ = true
--metrix.handle_ngx_phase("log")
--ngx.req.__INTERNAL__ = false
--metrix.handle_ngx_phase("log")
--
--ngx.var.hostname = "example.com"
--
--ngx.var.upstream_addr = '127.0.0.1'
--metrix.handle_ngx_phase("log")
--ngx.var.https = 'on'
--metrix.handle_ngx_phase("log")
--ngx.var.https = nil
--ngx.var.upstream_addr = nil
--ngx.req.__INTERNAL__ = true
--metrix.handle_ngx_phase("log")
--metrix.handle_ngx_phase("log")
--metrix.handle_ngx_phase("log")
--ngx.req.__INTERNAL__ = false
--ngx.status = 304
--metrix.handle_ngx_phase("log")
--ngx.status = 404
--metrix.set_hostname('myhostname.org')
--metrix.handle_ngx_phase("log")
--ngx.status = 200
--
--print("\n============ OUTPUT ============\n")
--metrix.show()
--
--print("\n========== DUMP STATE ==========\n")
--
---- DUMP STATE
--each(function(k,v) print(("\n--- %s ---\n%s"):format(k, inspect(v))) end, metrix.__private__)
