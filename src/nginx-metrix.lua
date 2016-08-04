local Logger = require 'nginx-metrix.logger'

local M = {}

M._version = '2.0-dev'
M._inited = nil
M._do_not_track = false

M._logger = Logger()
M._storage = nil
M._vhosts = nil
M._aggregator = nil
M._collectors = nil
M._scheduler = nil

---
-- @param options
--
function M._init_storage(options)
  M._storage = require 'nginx-metrix.storage'(options)
end

---
-- @param options
--
function M._init_vhosts(options)
  M._vhosts = require 'nginx-metrix.vhosts'(options, M._storage)
end

---
-- @param options
--
function M._init_aggregator(options)
  M._aggregator = require 'nginx-metrix.aggregator'(options, M._storage)
end

---
-- @param options
--
function M._init_scheduler(options)
  M._scheduler = require 'nginx-metrix.scheduler'(options, M._storage)
  M._scheduler.attach_action('aggregator.aggregate', M._aggregator.aggregate)
end

---
-- @param options
--
function M._init_collectors(options)
  M._collectors = require 'nginx-metrix.collectors'(options, M._storage)
end

---
-- @param collector
--
function M.register_collector(collector)
  M._collectors.register(collector)
end

---
-- @param options
--
function M.init(options)
  xpcall(function()
    M._init_storage(options)
    M._init_vhosts(options)
    M._init_scheduler(options)
    M._init_collectors(options)
    M._inited = true
  end,
    function(err)
      M._logger:err('Init failed. Metrix disabled.', err)
      M._inited = false
    end)
end

---
-- @param phase
--
function M._apply_markers(phase)
  M._logger:debug('_apply_markers', phase)
end

---
-- @param phase
--
function M._exec_collectors(phase)
  M._collectors.exec_all(phase)
end

---
--
function M.handle_ngx_phase()
  local phase = ngx.get_phase()

  M._apply_markers(phase)

  M._exec_collectors(phase)
end

------------------------------------------------------------------------------
return setmetatable(M, {
  __call = function(_, ...)
    M.init(...)
    return M
  end,
})
