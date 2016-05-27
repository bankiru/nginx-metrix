local exports = {}

local serialized_table_token = '@@lua_table@@'
local json = require 'dkjson'

---
-- @param value
-- @return string
---
local serialize = function(value)
    if type(value) == 'table' then
        value = serialized_table_token .. json.encode(value)
    end
    return value
end

---
-- @param value string json
-- @return mixed
---
local unserialize = function(value)
    if type(value) == 'string' and value:sub(1, serialized_table_token:len()) == serialized_table_token then
        local succ, decoded_value = pcall(function()
            return json.decode(value:sub(serialized_table_token:len() + 1))
        end)
        if succ then
            value = decoded_value
        end
    end
    return value
end
-- /serializer

--------------------------------------------------------------------------------
-- EXPORTS
--------------------------------------------------------------------------------

exports.serialize = serialize
exports.unserialize = unserialize

return exports