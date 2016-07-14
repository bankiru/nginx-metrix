local fun = require 'fun'
local Logger = require 'nginx-metrix.logger'

local M = {}

M._version = '2.0-dev'
M._inited = nil
M._do_not_track = false
M._builtin_collectors = fun.iter { 'request', 'status', 'upstream' }

M._logger = Logger('nginx-metrix')
M._storage = nil
M._vhosts = nil

---
-- @param options
--
function M.init_storage(options)
  M._storage = require 'nginx-metrix.storage'(options)
end

---
-- @param options
--
function M.init_vhosts(options)
  M._vhosts = require 'nginx-metrix.vhosts'(options, M._storage)
end

---
-- @param options
--
function M.init_builtin_collectors(options)
  if not options.skip_register_builtin_collectors then
    M._builtin_collectors:each(function(name)
      local collector = require('nginx-metrix.collectors.' .. name)
      M.register_collector(collector)
    end)
  end
end

---
-- @param options
--
function M.init(options)
  xpcall(function()
    M.init_storage(options)
    M.init_vhosts(options)
    M.init_builtin_collectors(options)
    M._inited = true
  end,
    function(err)
      M._logger:err('Init failed. Metrix disabled.', err)
      M._inited = false
    end)
end

return setmetatable(M, { __call = function(_, ...) M.init(...) end, })
