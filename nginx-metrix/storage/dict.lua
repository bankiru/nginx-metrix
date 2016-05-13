local exports = {}

local serializer = require 'nginx-metrix.storage.serializer'
local logger = require 'nginx-metrix.logger'

---
-- @param options table
---
local init = function(options)
    local shared_dict = options.shared_dict

    if type(shared_dict) == 'string' then
        assert(ngx.shared[shared_dict] ~= nil, ('lua_shared_dict "%s" does not defined.'):format(shared_dict))
        shared_dict = ngx.shared[shared_dict]
    end

    assert(type(shared_dict) == 'table', ('Invalid shared_dict type. Expected string or table, got %s.'):format(type(shared_dict)))

    local index = function(_, method)
        if shared_dict[method] == nil then
            logger.error(("dict method '%s' does not exists"):format(method))
            return nil
        end

        return function(...)
            return shared_dict[method](shared_dict, ...)
        end
    end

    exports._shared = shared_dict
    setmetatable(exports, {__index = index})
end

---
-- @param key
-- @return string
---
local normalize_key = function(key)
    assert(key ~= nil, 'key can not be nil')
    if type(key) ~= 'string' then key = tostring(key) end

    return key
end

---
-- @param key string
-- @return mixed,int
---
local get = function(key)
    local value, flags = exports._shared:get(normalize_key(key))
    return serializer.unserialize(value), (flags or 0)
end

---
-- @param key string
-- @return mixed,int,bool
----
local get_stale = function(key)
    local value, flags, stale = exports._shared:get_stale(normalize_key(key))
    return serializer.unserialize(value), (flags or 0), stale
end

---
-- @param key string
-- @param value mixed
-- @param exptime
-- @param flags int
-- @return mixed
---
local set = function(key, value, exptime, flags)
    return exports._shared:set(normalize_key(key), serializer.serialize(value), exptime or 0, flags or 0)
end

---
-- @param key string
-- @param value mixed
-- @param exptime
-- @param flags int
-- @return mixed
---
local safe_set = function(key, value, exptime, flags)
    return exports._shared:safe_set(normalize_key(key), serializer.serialize(value), exptime or 0, flags or 0)
end

---
-- @param key string
-- @param value mixed
-- @param exptime
-- @param flags int
-- @return mixed
---
local add = function(key, value, exptime, flags)
    return exports._shared:add(normalize_key(key), serializer.serialize(value), exptime or 0, flags or 0)
end

---
-- @param key string
-- @param value mixed
-- @param exptime
-- @param flags int
-- @return mixed
---
local safe_add = function(key, value, exptime, flags)
    return exports._shared:safe_add(normalize_key(key), serializer.serialize(value), exptime or 0, flags or 0)
end

---
-- @param key string
-- @param value mixed
-- @param exptime
-- @param flags int
-- @return mixed
---
local replace = function(key, value, exptime, flags)
    return exports._shared:replace(normalize_key(key), serializer.serialize(value), exptime or 0, flags or 0)
end

---
-- @param key string
--
local delete = function(key)
    exports._shared:delete(normalize_key(key))
end

---
-- @param key string
-- @param value mixed
-- @return mixed
---
local incr = function(key, value)
    if value ~= nil and type(value) ~= 'number' then value = tonumber(value) end
    return exports._shared:incr(normalize_key(key), value)
end

---
-- @param key string
-- @param value mixed
-- @return mixed
---
local safe_incr = function(key, value)
    key = normalize_key(key)
    if value == nil then value = 1 end
    if type(value) ~= 'number' then value = tonumber(value) end

    local new_value, err, _
    new_value, err = exports.incr(key, value)
    if err == 'not found' then
        new_value = value
        _, err = exports.add(key, new_value)
    end

    if err == nil then
        return new_value, nil
    else
        return nil, err
    end
end

--------------------------------------------------------------------------------
-- EXPORTS
--------------------------------------------------------------------------------

exports.init = init
exports.get = get
exports.get_stale = get_stale
exports.set = set
exports.safe_set = safe_set
exports.add = add
exports.safe_add = safe_add
exports.incr = incr
exports.safe_incr = safe_incr
exports.replace = replace
exports.delete = delete

if __TEST__ then
    exports.__private__ = {
        normalize_key = normalize_key
    }
end

return exports
