local fun = require 'fun'
local Logger = require 'nginx-metrix.logger'
local validator = require 'nginx-metrix.validator'

local M = {}

M._logger = Logger('collectors')
M._storage = nil

M._builtin = fun.iter { 'request', 'status', 'upstream' }
M._collectors = {}

---
-- @param collector
--
function M._exists(collector)
  return M._collectors[collector.name] ~= nil
end

---
-- @param collector
--
function M._validate(collector)
  validator.assert_type('table', collector,
    ('Collector must be a table. Got %s.'):format(type(collector)))

  validator.assert_type('string', collector.name,
    'Collector must contain a `name` property.')

  validator.assert_callable(collector.collect,
    ('Collector<%s>:collect must be a function or callable table. Got: %s.'):format(collector.name, type(collector.collect)))

  validator.assert_callable(collector.render,
    ('Collector<%s>:render must be a function or callable table. Got: %s.'):format(collector.name, type(collector.render)))
end

---
-- @param collector
--
function M.register(collector)
  M._validate(collector)

  if M._exists(collector) then
    error(('Collector<%s> already exists.'):format(collector.name))
  end
end

---
-- @param options
-- @param storage
--
function M.init(options, storage)
  M._storage = storage

  if not options.skip_register_builtin_collectors then
    M._builtin:each(function(name)
      local collector = require('nginx-metrix.collectors.' .. name)
      M.register(collector)
    end)
  end
end

---
-- @param phase
--
function M.exec_all(phase)
  fun.each(function(name, collector)
    M._logger:debug(('Collector<%s> called on phase `%s`.'):format(name, phase))
    collector:collect(phase)
  end,
    M._collectors)
end

------------------------------------------------------------------------------
return setmetatable(M, {
  __call = function(_, ...)
    M.init(...)
    return M
  end,
})
