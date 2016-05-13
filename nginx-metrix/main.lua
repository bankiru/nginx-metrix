local version = require 'nginx-metrix.version'

local do_not_track = false

--------------------------------------------------------------------------------
-- Libs and utils
--------------------------------------------------------------------------------
_ = package.loaded['fun'] or require 'fun'()
require 'nginx-metrix.lib.is'()

--------------------------------------------------------------------------------
-- Components
--------------------------------------------------------------------------------
local namespaces = require 'nginx-metrix.storage.namespaces'
local collectors = require 'nginx-metrix.collectors'
local listener   = require 'nginx-metrix.listener'
local scheduler  = require 'nginx-metrix.scheduler'
local output     = require 'nginx-metrix.output.renderer'

--------------------------------------------------------------------------------
-- Collectors functions
--------------------------------------------------------------------------------
local builtin_collectors = iter({[[request]], [[status]], [[upstream]]})

---
-- @param collector
---
local register_collector = function(collector)
    collector = collectors.register(collector)

    listener.attach_collector(collector)
    scheduler.attach_collector(collector)
end

---
--
local register_builtin_collectors = function()
    builtin_collectors:each(function(name)
        local collector = require('nginx-metrix.collectors.' .. name)
        register_collector(collector)
    end)
end

--------------------------------------------------------------------------------
-- Handling nginx phases
--------------------------------------------------------------------------------

---
-- @param phase string
---
local handle_ngx_phase = function(phase)
    namespaces.activate(ngx.var.server_name or ngx.var.hostname)

    if do_not_track then
        do_not_track = false
    else
        listener.handle_phase(phase)
    end
end

--------------------------------------------------------------------------------
-- Scheduler
--------------------------------------------------------------------------------
---
--
local init_scheduler = function()
    scheduler.start()
end

--------------------------------------------------------------------------------
-- Output
--------------------------------------------------------------------------------
---
-- @param _do_not_track bool default true
---
local show = function(_do_not_track)
    namespaces.activate(ngx.var.server_name or ngx.var.hostname)

    output.render()

    if _do_not_track ~= nil then
        do_not_track = _do_not_track
    else
        do_not_track = true
    end
end

--------------------------------------------------------------------------------
-- EXPORTS
--------------------------------------------------------------------------------
local exports = {}
exports.version = version
exports.register_collector = register_collector
exports.register_builtin_collectors = register_builtin_collectors
exports.handle_ngx_phase = handle_ngx_phase
exports.init_scheduler = init_scheduler
exports.show = show

if __TEST__ then
    exports.__private__ = {
        collectors = collectors,
    }
end

return function(options)
    require('nginx-metrix.storage.dict').init(options)

    if not options.skip_register_builtin_collectors then
        register_builtin_collectors()
    end

    return exports
end
