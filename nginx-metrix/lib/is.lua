local exports = {}

local callable
callable = function(obj)
    return type(obj) == 'function' or type(obj) == 'table' and getmetatable(obj) and callable(getmetatable(obj).__call)
end

exports.callable = callable

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