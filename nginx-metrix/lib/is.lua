local exports = {}

exports.callable = function(obj)
    return type(obj) == 'function' or getmetatable(obj) and getmetatable(obj).__call and true
end

setmetatable(exports, {
    __call = function(t)
        if _G.is == nil or type(_G.is) ~= 'table' then
            _G.is = t
        else
            for k, v in pairs(t) do
                _G.is[k] = v
            end
        end
        return exports
    end,
})

return exports