local json = require 'dkjson'
local Logger = require 'nginx-metrix.logger'

local M = {}

M._serialized_table_token = '@@lua_table@@'
M._logger = Logger('serializer')

---
-- @param value
-- @return string
---
function M.serialize(value)
  if type(value) == 'table' then
    value = M._serialized_table_token .. json.encode(value)
  end
  return value
end

---
-- @param value string json
-- @return mixed
---
function M.unserialize(value)
  if type(value) == 'string' and value:sub(1, M._serialized_table_token:len()) == M._serialized_table_token then
    local result, _, err = json.decode(value:sub(M._serialized_table_token:len() + 1))
    if err then
      M._logger:err('Can not unserialize value: ' .. err, value)
    else
      value = result
    end
  end
  return value
end

return M
