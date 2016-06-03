local namespaces = require 'nginx-metrix.storage.namespaces'
local storage_dict = require 'nginx-metrix.storage.dict'

local key_sep_namespace = 'ː'
local key_sep_collector = '¦'

---
-- @param str
-- @return string
---
local normalize_string = function(str)
  return str:gsub(key_sep_namespace, '_'):gsub(key_sep_collector, '_')
end

local wrapper_metatable = {}
wrapper_metatable.__index = wrapper_metatable

---
-- @param self
-- @param key
-- @return string
---
wrapper_metatable.prepare_key = function(self, key)
  assert(key ~= nil, ('key can not be nil'))
  if type(key) ~= 'string' then key = tostring(key) end

  key = normalize_string(key)

  local key_prefix = ''

  if self.collector_name ~= nil then
    key_prefix = normalize_string(self.collector_name) .. key_sep_collector .. key_prefix
  end

  if namespaces.active() ~= nil then
    key_prefix = normalize_string(namespaces.active()) .. key_sep_namespace .. key_prefix
  end

  return key_prefix .. key
end

---
-- @param key string
-- @return mixed,int
---
wrapper_metatable.get = function(self, key)
  return storage_dict.get(self:prepare_key(key))
end

---
-- @param key string
-- @return mixed,int,bool
----
wrapper_metatable.get_stale = function(self, key)
  return storage_dict.get_stale(self:prepare_key(key))
end

---
-- @param key string
-- @param value mixed
-- @param exptime
-- @param flags int
-- @return mixed
---
wrapper_metatable.set = function(self, key, value, exptime, flags)
  return storage_dict.set(self:prepare_key(key), value, exptime, flags)
end

---
-- @param key string
-- @param value mixed
-- @param exptime
-- @param flags int
-- @return mixed
---
wrapper_metatable.safe_set = function(self, key, value, exptime, flags)
  return storage_dict.safe_set(self:prepare_key(key), value, exptime, flags)
end

---
-- @param key string
-- @param value mixed
-- @param exptime
-- @param flags int
-- @return mixed
---
wrapper_metatable.add = function(self, key, value, exptime, flags)
  return storage_dict.add(self:prepare_key(key), value, exptime, flags)
end

---
-- @param key string
-- @param value mixed
-- @param exptime
-- @param flags int
-- @return mixed
---
wrapper_metatable.safe_add = function(self, key, value, exptime, flags)
  return storage_dict.safe_add(self:prepare_key(key), value, exptime, flags)
end

---
-- @param key string
-- @param value mixed
-- @param exptime
-- @param flags int
-- @return mixed
---
wrapper_metatable.replace = function(self, key, value, exptime, flags)
  return storage_dict.replace(self:prepare_key(key), value, exptime, flags)
end

---
-- @param key string
--
wrapper_metatable.delete = function(self, key)
  storage_dict.delete(self:prepare_key(key))
end

---
-- @param key string
-- @param value mixed
-- @return mixed
---
wrapper_metatable.incr = function(self, key, value)
  return storage_dict.incr(self:prepare_key(key), value)
end

---
-- @param key string
-- @param value mixed
-- @return mixed
---
wrapper_metatable.safe_incr = function(self, key, value)
  return storage_dict.safe_incr(self:prepare_key(key), value)
end

---
-- @param key string
-- @param value number
-- @return mixed
---
wrapper_metatable.mean_add = function(self, key, value)
  key = self:prepare_key(key)
  local prev_value, counter = storage_dict.get(key)
  value = ((prev_value or 0) * counter + value) / (counter + 1)
  return storage_dict.set(key, value, nil, counter + 1)
end

---
-- @param key string
---
wrapper_metatable.mean_flush = function(self, key)
  key = self:prepare_key(key)
  local prev_value, counter = storage_dict.get(key)
  if counter > 0 then
    counter = 1
  end
  storage_dict.set(key, (prev_value or 0), 0, counter)
end

---
-- @param key string
-- @param value number
-- @return mixed
---
wrapper_metatable.cyclic_incr = function(self, key, value)
  return storage_dict.safe_incr(self:prepare_key(key) .. '^^next^^', value)
end

---
-- @param key string
---
wrapper_metatable.cyclic_flush = function(self, key)
  key = self:prepare_key(key)
  local next_key = key .. '^^next^^'
  local next_value = storage_dict.get(next_key) or 0
  storage_dict.delete(next_key)
  storage_dict.set(key, next_value, 0, 0)
end

---
-- Factory method
-- @param collector
---
local create = function(collector)
  local wrapper = {
    collector_name = collector.name
  }

  setmetatable(wrapper, wrapper_metatable)

  return wrapper
end

--------------------------------------------------------------------------------
-- EXPORTS
--------------------------------------------------------------------------------

local exports = {}
exports.create = create

if __TEST__ then
  exports.__private__ = {
    wrapper_metatable = wrapper_metatable
  }
end

return exports
