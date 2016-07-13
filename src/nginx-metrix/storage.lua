local fun = require 'fun'
local Logger = require 'nginx-metrix.logger'

local M = {}

M._shared_dict = nil
M._logger = Logger('nginx-metrix.storage')

local index = function(_, method)
  if M._shared_dict[method] == nil then
    M._logger.error(("dict method '%s' does not exists"):format(method))
    return nil
  end

  return function(...)
    return M._shared_dict[method](M._shared_dict, ...)
  end
end

---
-- @param options
--
function M.init(options)
  M._shared_dict = options.shared_dict

  if type(M._shared_dict) == 'string' then
    assert(ngx.shared[M._shared_dict] ~= nil, ('lua_shared_dict "%s" does not defined.'):format(M._shared_dict))
    M._shared_dict = ngx.shared[M._shared_dict]
  end

  assert(type(M._shared_dict) == 'table', ('Invalid shared_dict type. Expected string or table, got %s.'):format(type(M._shared_dict)))
end

return setmetatable(M, {
  __call = function(_, ...) M.init(...) end,
  __index = index
})
