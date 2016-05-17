local inspect = require 'inspect'

local phases = {
    [[init]],
    [[access]],
    [[content]],
    [[log]],
    [[body-filter]],
    [[header-filter]],
    [[rewrite]],
    [[ssl_certificate]],
    [[init_worker]],
}

local handlers = zip(phases, duplicate({})):tomap()

---
-- @param collector table
--
local attach_collector = function(collector)
    iter(collector.ngx_phases):each(function(phase)
        assert(
            index(phase, phases) ~= nil,
            ('Collector<%s>.ngx_phases[%s] invalid, phase "%s" does not exists'):format(collector.name, phase, phase)
        )

        table.insert(handlers[phase], collector)
    end)
end

---
-- @param phase string
---
local handle_phase = function(phase)
    phase = phase or ngx.get_phase()

    assert(
        type(phase) == 'string' and index(phase, phases) ~= nil,
        ('Invalid ngx phase %s (%s)'):format(inspect(phase), type(phase))
    )

    iter(handlers[phase]):each(function(collector)
        collector:handle_ngx_phase(phase)
    end)
end

--------------------------------------------------------------------------------
-- EXPORTS
--------------------------------------------------------------------------------
local exports = {}
exports.attach_collector = attach_collector
exports.handle_phase = handle_phase

if __TEST__ then
    exports.__private__ = {
        phases = phases,
        get_handlers = function() return handlers end,
    }
end

return exports