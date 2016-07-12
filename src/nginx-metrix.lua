local fun = require 'fun'

local M = {}

M.version = '2.0-dev'
M.do_not_track = false
M.builtin_collectors = fun.iter { 'request', 'status', 'upstream' }
M.storage = nil
M.vhosts = nil

function M.init_storage(options)
  M.storage = require 'nginx-metrix.storage'(options)
end

function M.init_vhosts(options)
  M.vhosts = require 'nginx-metrix.vhosts'(options)
end

function M.init_builtin_collectors(options)
  if not options.skip_register_builtin_collectors then
    M.builtin_collectors:each(function(name)
      local collector = require('nginx-metrix.collectors.' .. name)
      M.register_collector(collector)
    end)
  end
end

function M.init(options)
  M.init_storage(options)
  M.init_vhosts(options)
  M.init_builtin_collectors(options)
end

return setmetatable(M, { __call = function(_, options) M.init(options) end, })
