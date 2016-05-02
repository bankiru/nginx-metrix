local storage_dict = require 'nginx-metrix.storage.dict'

local namespaces_list_key = 'namespaces'

local active_namespace
local list_cache = {}

---
-- @return table
---
local list = function()
    local namespaces = storage_dict.get(namespaces_list_key)
    if type(namespaces) ~= 'table' then
        namespaces = {}
    end

    return namespaces
end

---
-- @param namespaces table
---
local set = function(namespaces)
    assert(type(namespaces) == 'table' or type(namespaces) == 'string', 'namespaces should be table of strings or single string, got' .. type(namespaces))

    if type(namespaces) == 'string' then
        namespaces = {namespaces}
    end

    if all(function(namespace) return index(namespace, list_cache) ~= nil end, namespaces) then
        return
    end

    list_cache = list()

    iter(namespaces):each(function(namespace)
        if index(namespace, list_cache) == nil then
            table.insert(list_cache, namespace)
        end
    end)

    storage_dict.set(namespaces_list_key, list_cache)
end

---
-- @param namespace
---
local activate = function(namespace)
    assert(namespace == nil or type(namespace) == 'string', 'Expected string or nil value for namespace, got ' .. type(namespace))
    active_namespace = namespace
    set(namespace)
end

---
--
local reset_active = function()
    active_namespace = nil
end

---
--
local active = function()
    return active_namespace
end

---
-- @param options table
---
local init = function(options)
    if options.namespaces then
        assert(type(options.namespaces) == 'table', ('Invalid namespaces type. Expected table, got %s.'):format(type(options.namespaces)))

        set(options.namespaces)
    end
end

--------------------------------------------------------------------------------
-- EXPORTS
--------------------------------------------------------------------------------

local exports = {}
exports.init = init
exports.active = active
exports.activate = activate
exports.reset_active = reset_active
exports.list = list
exports.set = set

if __TEST__ then
    exports.__private__ = {
        namespaces_list_key = namespaces_list_key,
        get_list_cache = function() return list_cache end,
        set_list_cache = function(value) list_cache = value end,
    }
end

return exports
