--local fun = require 'fun'
local Logger = require 'nginx-metrix.logger'
local serializer = require 'nginx-metrix.serializer'

local M = {}

M._shared_dict = nil
M._logger = Logger('nginx-metrix.storage')

---
-- @param _
-- @param method
--
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

---
-- @param key
-- @return string
---
function M._normalize_key(key)
  assert(key ~= nil, 'key can not be nil')
  if type(key) ~= 'string' then key = tostring(key) end

  return key
end

---
-- @param key string
-- @return mixed,int
---
function M.get(key)
  local value, flags = M._shared_dict:get(M._normalize_key(key))
  return serializer.unserialize(value), (flags or 0)
end

---
-- @param key string
-- @return mixed,int,bool
----
function M.get_stale(key)
  local value, flags, stale = M._shared_dict:get_stale(M._normalize_key(key))
  return serializer.unserialize(value), (flags or 0), stale
end

---
-- @param key string
-- @param value mixed
-- @param exptime
-- @param flags int
-- @return mixed
---
function M.set(key, value, exptime, flags)
  return M._shared_dict:set(M._normalize_key(key), serializer.serialize(value), exptime or 0, flags or 0)
end

---
-- @param key string
-- @param value mixed
-- @param exptime
-- @param flags int
-- @return mixed
---
function M.safe_set(key, value, exptime, flags)
  return M._shared_dict:safe_set(M._normalize_key(key), serializer.serialize(value), exptime or 0, flags or 0)
end

---
-- @param key string
-- @param value mixed
-- @param exptime
-- @param flags int
-- @return mixed
---
function M.add(key, value, exptime, flags)
  return M._shared_dict:add(M._normalize_key(key), serializer.serialize(value), exptime or 0, flags or 0)
end

---
-- @param key string
-- @param value mixed
-- @param exptime
-- @param flags int
-- @return mixed
---
function M.safe_add(key, value, exptime, flags)
  return M._shared_dict:safe_add(M._normalize_key(key), serializer.serialize(value), exptime or 0, flags or 0)
end

---
-- @param key string
-- @param value mixed
-- @param exptime
-- @param flags int
-- @return mixed
---
function M.replace(key, value, exptime, flags)
  return M._shared_dict:replace(M._normalize_key(key), serializer.serialize(value), exptime or 0, flags or 0)
end

---
-- @param key string
--
function M.delete(key)
  M._shared_dict:delete(M._normalize_key(key))
end

---
-- @param key string
-- @param value mixed
-- @return mixed
---
function M.incr(key, value)
  if value ~= nil and type(value) ~= 'number' then value = tonumber(value) end
  return M._shared_dict:incr(M._normalize_key(key), value)
end

---
-- @param key string
-- @param value mixed
-- @return mixed
---
function M.safe_incr(key, value)
  key = M._normalize_key(key)
  if value == nil then value = 1 end
  if type(value) ~= 'number' then value = tonumber(value) end

  local new_value, err, _
  new_value, err = M.incr(key, value)
  if err == 'not found' then
    new_value = value
    _, err = M.add(key, new_value)
  end

  if err == nil then
    return new_value, nil
  else
    return nil, err
  end
end

return setmetatable(M, {
  __call = function(_, ...)
    M.init(...)
    return M
  end,
  __index = index
})

