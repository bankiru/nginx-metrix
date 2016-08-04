local fun = require 'fun'
local Logger = require 'nginx-metrix.logger'

local M = {}

M._logger = Logger('collectors')
M._storage = nil

M._builtin = fun.iter { 'request', 'status', 'upstream' }

function M.register(collector)
  M._logger:debug('Registering collector', collector)
  error('Not implemented yet')
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
  M._logger:debug('exec_all', phase)
  error('Not implemented yet')
end

------------------------------------------------------------------------------
return setmetatable(M, {
  __call = function(_, ...)
    M.init(...)
    return M
  end,
})
