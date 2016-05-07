local exports = {}

local inspect = require 'inspect'

exports.log = function(level, msg, ...)
    if type(msg) ~= 'string' then
        msg = inspect(msg)
    end

    local additional = ...
    if type(additional) == 'table' and length(additional) > 0 then
        msg = msg .. ' :: ' .. inspect(additional)
    end

    ngx.log(level, msg)
end

exports.error = function(...)
    exports.log(ngx.ERROR, ...)
end

exports.stderror = function(...)
    exports.log(ngx.STDERR, ...)
end

setmetatable(exports, {
    __call = function(_)
        _G.logger = exports
        return exports
    end,
})

return exports