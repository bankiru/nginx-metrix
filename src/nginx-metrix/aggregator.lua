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

function M.aggregate(worker_id)
  M._logger:debug(('Aggregating on worker #%s'):format(worker_id))
  error('Not implemented yet')
end

------------------------------------------------------------------------------
return setmetatable(M, {
  __call = function(_, ...)
    M.init(...)
    return M
  end,
})
