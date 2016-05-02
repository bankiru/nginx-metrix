local exports = {}

local inspect = require 'inspect'

exports.log = function(level, msg)
    if type(msg) ~= 'string' then
        msg = inspect(msg)
    end

    ngx.log(level, msg)
end

exports.error = function(msg)
    exports.log(ngx.ERROR, msg)
end

exports.stderror = function(msg)
    exports.log(ngx.STDERR, msg)
end

setmetatable(exports, {
    __call = function(_)
        _G.logger = exports
        return exports
    end,
})

return exports