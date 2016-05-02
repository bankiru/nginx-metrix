_G.ngx = {}

local ngx_origin = {
    header = {
        content_type = nil
    },
    localtime = function() return os.date ('%F %T') end,
    req = {
        __INTERNAL__ = false,
        __URI_ARGS__ = {},
        __HEADERS__ = {['accept'] = 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8'},
        is_internal = function() return ngx.req.__INTERNAL__ end,
        get_uri_args = function() return ngx.req.__URI_ARGS__ end,
        get_headers = function() return ngx.req.__HEADERS__ end,
    },
    say = function(...) print(require 'inspect'({...})); print(...) end,
    shared = {},
    status = 200,
    var = {
        hostname = '_',
        https = nil,
        request_length = 128,
        request_time = 0.123,
        upstream_addr = nil,
        upstream_connect_time = 0.01,
        upstream_header_time = 0.02,
        upstream_response_time = 0.321,
    },
}

local reset = function()
    _G.ngx = copy(ngx_origin)
end

local define_shared_dict = function(name)
    local function assert_key(key)
        assert(type(key) == 'string', ('Invalid key type; Expected string; Got %s'):format(type(key)))
        assert(key ~= '', 'key is empty')
    end

    local function assert_value(value)
        local allowed_types = {['nil']=true, ['boolean']=true, ['number']=true, ['string']=true,}
        assert(allowed_types[type(value)], ('Invalid value type; Expected boolean, number, string or nil; Got %s'):format(type(value)))
    end

    local function assert_flags(flags)
        assert(flags == nil or type(flags) == 'number', ('Invalid flags type; Expected number; Got %s'):format(type(flags)))
    end

    local shared_dict_meta_table = {}

    function shared_dict_meta_table:get(key)
        assert_key(key)
        local record = self[key]
        local value = record and record['value']
        local flags = record and record['flags'] or 0
        return value, flags
    end

    function shared_dict_meta_table:get_stale(key)
        local value, flags = self:get(key)
        return value, flags, false
    end

    function shared_dict_meta_table:set(key, value, exptime, flags)
        assert_key(key)
        assert_value(value)
        assert_flags(flags)

        self[key] = {['value']=value, ['flags']=(flags or 0)}
        return true, nil, false
    end

    function shared_dict_meta_table:safe_set(key, value, exptime, flags)
        local success, err, _ = self:set(key, value, exptime, flags)
        return success, err
    end

    function shared_dict_meta_table:add(key, value, exptime, flags)
        assert_key(key)
        assert_value(value)
        assert_flags(flags)

        if self[key] ~= nil then
            return false, 'exists'
        end

        return self:set(key, value, exptime, flags)
    end

    function shared_dict_meta_table:safe_add(key, value, exptime, flags)
        local success, err, _ = self:add(key, value, exptime, flags)
        return success, err
    end

    function shared_dict_meta_table:replace(key, value, exptime, flags)
        assert_key(key)
        assert_value(value)
        assert_flags(flags)

        if self[key] == nil then
            return false, 'not found'
        end

        return self:set(key, value, exptime, flags)
    end

    function shared_dict_meta_table:delete(key)
        assert_key(key)

        self[key] = nil
    end

    function shared_dict_meta_table:incr(key, value)
        assert_key(key)
        assert(type(value) == 'number', ('Invalid value type; Expected number; Got %s'):format(type(value)))

        if self[key] == nil then
            return nil, 'not found'
        end

        if type(self[key].value) ~= 'number' then
            return nil, 'not a number'
        end

        self[key].value = self[key].value + value

        return self[key].value, nil
    end

    function shared_dict_meta_table:flush_all()
        for k,_ in pairs(self) do
            self[k] = nil
        end
    end

    function shared_dict_meta_table:flush_expired()
    end

    function shared_dict_meta_table:get_keys()
        local keyset={}

        for k,_ in pairs(self) do
            table.insert(keyset, k)
        end

        return keyset
    end

    -- -- -- -- --
    shared_dict_meta_table.__index = shared_dict_meta_table

    local dict = {}
    setmetatable(dict, shared_dict_meta_table)

    ngx.shared[name] = dict

    return dict
end

local exports = {}
exports.reset = reset
exports.define_shared_dict = define_shared_dict

setmetatable(exports, {
    __call = function(_)
        reset()
        return exports
    end,
})

return exports