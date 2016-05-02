local exports = {}

local collectors = {{name = 'dummy'}} -- dummy item for correct work iter function
local collectors_iter = iter(collectors)
table.remove(collectors, 1) -- removing dummy item

local ngx_phases_available = {}

---
-- @param collector table
-- @return bool
---
local collector_exists = function(collector)
    return index(collector.name, collectors_iter:map(function(c) return c.name end)) ~= nil
end

---
-- @param collector table
---
local collector_validate = function(collector)
    assert(
        type(collector) == 'table',
        ('Collector MUST be a table, got %s: %s'):format(type(collector), inspect(collector))
    )

    assert(
        type(collector.name) == 'string',
        ('Collector must have string property "name", got %s: %s'):format(type(collector.name), inspect(collector))
    )

    -- collector exists
    assert(
        not collector_exists(collector),
        ('Collector<%s> already exists'):format(collector.name)
    )

    assert(
        type(collector.ngx_phases) == 'table',
        ('Collector<%s>.ngx_phases must be an array, given: %s'):format(collector.name, type(collector.ngx_phases))
    )

    assert(
        all(function(phase) return type(phase) == 'string' end, collector.ngx_phases),
        ('Collector<%s>.ngx_phases must be an array of strings, given: %s'):format(collector.name, inspect(collector.ngx_phases))
    )

    each(
        function(phase)
            assert(
                index(phase, ngx_phases_available) ~= nil,
                ('Collector<%s>.ngx_phases[%s] invalid, phase "%s" does not exists'):format(collector.name, phase, phase)
            )

            assert(
                is_callable(collector.handle_ngx_phase),
                ('Collector<%s>:handle_phase must be a function or callable table, given: %s'):format(collector.name, phase, type(collector.handle_ngx_phase))
            )
        end,
        collector.ngx_phases
    )

    assert(
        type(collector.fields) == 'table',
        ('Collector<%s>.fields must be a table, given: %s'):format(collector.name, type(collector.fields))
    )

    assert(
        all(function(field, params) return type(field) == 'string' and type(params) == 'table' end, collector.fields),
        ('Collector<%s>.fields must be an table[string, table], given: %s'):format(collector.name, inspect(collector.fields))
    )
end

---
-- @param collector table
-- @return table
---
local collector_extend = function(collector)
    local _metatable = {}
    _metatable.init = function(self, storage, output_tools)
        self.storage = storage
        self.output_tools = output_tools
    end
    _metatable.get_raw_stats = function(self)
        return map(
            function(k)
                return k, (self.storage:get(k) or 0)
            end,
            table.keys(self.fields)
        )
    end
    _metatable.get_text_stats = function(self)
        return self.output_tools.text.render_stats(self)
    end
    _metatable.get_html_stats = function(self)
        return self.output_tools.html.render_stats(self)
    end
    _metatable.__index = _metatable

    setmetatable(collector, _metatable)

    return collector
end

---
-- @param collector table
-- @return table
---
local collector_register = function(collector, storage_tools, output_tools)
    collector_validate(collector)

    collector = collector_extend(collector, storage_tools, output_tools)

    local storage = storage_tools.create_for_collector(collector)
    collector:init(storage, output_tools)

    table.insert(collectors, collector)

    return collector
end

--------------------------------------------------------------------------------
-- EXPORTS
--------------------------------------------------------------------------------
exports.register = collector_register
exports.all      = collectors_iter

setmetatable(exports, {
    __call = function(_, ngx_phases_handlers)
        ngx_phases_available = map(function(k) return k end, ngx_phases_handlers)
        return exports
    end,
})

return exports