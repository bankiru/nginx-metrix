local exports = {}

local shared_dict = {}

--------------------------------------------------------------------------------
-- Serializing
--------------------------------------------------------------------------------
local serialized_table_token = '@@lua_table@@'

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
-- Namespaces
--------------------------------------------------------------------------------
local namespaces_list_key = 'namespaces'

local namespace

---
-- @param _namespace
---
local set_namespace = function(_namespace)
    assert(_namespace == nil or type(_namespace) == 'string', 'Expected string or nil value for namespace, got ' .. type(_namespace))
    namespace = _namespace
end

---
--
local reset_namespace = function()
    namespace = nil
end

---
-- @return table
---
local get_namespaces = function()
    local list,_ = shared_dict:get(namespaces_list_key)
    if type(list) == 'string' then
        _, list = pcall(function()
            return json.decode(list)
        end)
    end
    if type(list) ~= 'table' then
        list = {}
    end

    return list
end

---
-- @param namespaces table
---
local set_namespaces = function(namespaces)
    assert(type(namespaces) == 'table', 'namespaces should be table, got' .. type(namespaces))

    shared_dict:set(
        namespaces_list_key,
        json.encode(
            map(
                function(k, v) return v or k end,
                namespaces
            ):totable()
        )
    )
end

---
-- @param namespace
-- @return void
---
local store_namespace = function(namespace)
    local list = get_namespaces()

    if index(namespace, list) ~= nil then return end

    table.insert(list, namespace)

    set_namespaces(list)
end

--------------------------------------------------------------------------------
-- Collectors
--------------------------------------------------------------------------------
---
-- @param collector current collector
-- @return table which wraps shared_dict with additional functions
---
local create_for_collector = function(collector)
    local key_sep_namespace = 'ː'
    local key_sep_collector = '¦'

    local collector_name = collector and collector.name

    ---
    -- @param key
    -- @return string
    ---
    local prepare_key = function(key)
        assert(key ~= nil, ('key can not be nil'))
        if type(key) ~= 'string' then key = tostring(key) end

        local normalize_string = function(str)
            return str:gsub(key_sep_namespace, '_'):gsub(key_sep_collector, '_')
        end

        key = normalize_string(key)

        local key_prefix = ''

        if collector_name ~= nil then
            key_prefix = normalize_string(collector_name) .. key_sep_collector .. key_prefix
        end

        if namespace ~= nil then
            store_namespace(namespace)
            key_prefix = normalize_string(namespace) .. key_sep_namespace .. key_prefix
        end

        return key_prefix .. key
    end

    local wrapped_dict = {}

    ---
    -- @param key string
    -- @return mixed,int
    ---
    function wrapped_dict:get(key)
        local value, flags = shared_dict:get(prepare_key(key))
        return unserialize(value), flags
    end

    ---
    -- @param key string
    -- @return mixed,int,bool
    ----
    function wrapped_dict:get_stale(key)
        local value, flags, stale = shared_dict:get_stale(prepare_key(key))
        return unserialize(value), flags, stale
    end

    ---
    -- @param key string
    -- @param value mixed
    -- @param exptime
    -- @param flags int
    -- @return mixed
    ---
    function wrapped_dict:set(key, value, exptime, flags)
        return shared_dict:set(prepare_key(key), serialize(value), exptime, flags)
    end

    ---
    -- @param key string
    -- @param value mixed
    -- @param exptime
    -- @param flags int
    -- @return mixed
    ---
    function wrapped_dict:safe_set(key, value, exptime, flags)
        return shared_dict:safe_set(prepare_key(key), serialize(value), exptime, flags)
    end

    ---
    -- @param key string
    -- @param value mixed
    -- @param exptime
    -- @param flags int
    -- @return mixed
    ---
    function wrapped_dict:add(key, value, exptime, flags)
        return shared_dict:add(prepare_key(key), serialize(value), exptime, flags)
    end

    ---
    -- @param key string
    -- @param value mixed
    -- @param exptime
    -- @param flags int
    -- @return mixed
    ---
    function wrapped_dict:safe_add(key, value, exptime, flags)
        return shared_dict:safe_add(prepare_key(key), serialize(value), exptime, flags)
    end

    ---
    -- @param key string
    -- @param value mixed
    -- @param exptime
    -- @param flags int
    -- @return mixed
    ---
    function wrapped_dict:replace(key, value, exptime, flags)
        return shared_dict:replace(prepare_key(key), serialize(value), exptime, flags)
    end

    ---
    -- @param key string
    --
    function wrapped_dict:delete(key)
        shared_dict:delete(prepare_key(key))
    end

    ---
    -- @param key string
    -- @param value mixed
    -- @return mixed
    ---
    function wrapped_dict:incr(key, value)
        if value ~= nil and type(value) ~= 'number' then value = tonumber(value) end
        return shared_dict:incr(prepare_key(key), value)
    end

    ---
    -- @param key string
    -- @param value mixed
    -- @return mixed
    ---
    function wrapped_dict:incr_safe(key, value)
        key = prepare_key(key)
        if value == nil then value = 1 end
        if type(value) ~= 'number' then value = tonumber(value) end

        local new_value, err
        new_value, err = shared_dict:incr(key, value)
        if err == 'not found' then
            new_value = value
            _, err = shared_dict:add(key, new_value)
        end

        if err == nil then
            return new_value, nil
        else
            return nil, err
        end
    end

    ---
    --
    function wrapped_dict:flush_all()
        each(function(k) self:delete(k) end, self:get_keys())
    end

    ---
    --
    function wrapped_dict:flush_expired()
        return shared_dict:flush_expired()
    end

    ---
    -- @return table
    ---
    function wrapped_dict:get_keys()
        local keys = iter(shared_dict:get_keys())

        if not is_null(keys) then
            local key_prefix = prepare_key('')

            keys = keys:filter(
                function(k)
                    return k ~= namespaces_list_key and (key_prefix == '' or k:sub(1,key_prefix:len()) == key_prefix)
                end
            ):map(
                function(k)
                    return k:sub(key_prefix:len()+1)
                end
            )
        end

        return keys:totable()
    end

    return wrapped_dict
end

---
-- @param _shared_dict
-- @return table
---
local init_shared_dict = function(_shared_dict)
    if type(_shared_dict) == 'string' then
        assert(
            ngx.shared[_shared_dict] ~= nil,
            ('lua_shared_dict %s does not defined'):format(_shared_dict)
        )

        _shared_dict = ngx.shared[_shared_dict]
    end

    assert(
        type(_shared_dict) == 'table',
        ('Invalid shared_dict type. Expected string or table, got %s'):format(type(_shared_dict))
    )

    shared_dict = _shared_dict

    return _shared_dict
end

---------------------------
-- EXPORT
---------------------------

exports.init_shared_dict = init_shared_dict
exports.create_for_collector = create_for_collector
exports.set_namespace = set_namespace
exports.reset_namespace = reset_namespace
exports.get_namespaces = get_namespaces
exports.set_namespaces = set_namespaces

if __TEST__ then
    exports.__private__ = {
        serialize = serialize,
        unserialize = unserialize,
        shared_dict = shared_dict,
    }
end

return exports
