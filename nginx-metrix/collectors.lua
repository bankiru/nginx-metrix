local inspect = require 'inspect'
local storage_collector_wrapper_factory = require 'nginx-metrix.storage.collector_wrapper_factory'

local exports = {}

local collectors = { { name = 'dummy' } } -- dummy item for correct work iter function
local collectors_iter = iter(collectors)
table.remove(collectors, 1) -- removing dummy item

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

  assert(
    is.callable(collector.on_phase),
    ('Collector<%s>:on_phase must be a function or callable table, given: %s'):format(collector.name, type(collector.on_phase))
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
  local _metatable = {
    init = function(self, storage)
      self.storage = storage
    end,
    handle_ngx_phase = function(self, phase)
      self:on_phase(phase)
    end,
    aggregate = function(self)
      iter(self.fields):each(function(field, params)
        if params.mean then
          self.storage:mean_flush(field)
        elseif params.cyclic then
          self.storage:cyclic_flush(field, params.window)
        end
      end)
    end,
    get_raw_stats = function(self)
      return iter(self.fields):map(function(k, _)
        return k, (self.storage:get(k) or 0)
      end)
    end,
    get_text_stats = function(self, output_helper)
      return output_helper.render_stats(self)
    end,
    get_html_stats = function(self, output_helper)
      return output_helper.render_stats(self)
    end
  }
  _metatable.__index = _metatable

  setmetatable(collector, _metatable)

  return collector
end

---
-- @param collector table
-- @return table
---
local collector_register = function(collector)
  collector_validate(collector)

  collector = collector_extend(collector)

  local storage = storage_collector_wrapper_factory.create(collector)
  collector:init(storage)

  table.insert(collectors, collector)

  return collector
end

--------------------------------------------------------------------------------
-- EXPORTS
--------------------------------------------------------------------------------
exports.register = collector_register
exports.all = collectors_iter
exports.set_window_size = storage_collector_wrapper_factory.set_window_size

if __TEST__ then
  exports.__private__ = {
    collectors = function(value)
      if value ~= nil then
        local count = length(collectors)
        while count > 0 do table.remove(collectors); count = count - 1 end
        iter(value):each(function(collector) table.insert(collectors, collector) end)
      end
      return collectors
    end,
    collector_exists = collector_exists,
    collector_extend = collector_extend,
    collector_validate = collector_validate,
  }
end

return exports
