local Logger = require 'nginx-metrix.logger'

local M = {}

M._logger = Logger('aggregator')
M._storage = nil
M._default_window_size = nil

---
-- @param options
-- @param storage
--
function M.init(options, storage)
  M._storage = storage

  if options.default_window_size ~= nil then
    M._default_window_size = options.default_window_size
  end
end

function M.register_metric(metric)
  M._logger:debug('register_metric', metric)
  error('Not implemented yet')
end

function M.update_metric_value(metric, value)
  M._logger:debug('update_metric_value', metric, value)
  error('Not implemented yet')
end

function M.get_metrics_values()
  M._logger:debug('get_metrics_values')
  error('Not implemented yet')
end

function M.aggregate()
  M._logger:debug('Aggregating')
  error('Not implemented yet')
end

------------------------------------------------------------------------------
return setmetatable(M, {
  __call = function(_, ...)
    M.init(...)
    return M
  end,
})
