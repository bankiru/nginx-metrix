local inspect = require 'inspect'

local log = function(level, msg, ...)
    if type(msg) ~= 'string' then
        msg = inspect(msg)
    end

    if length({ ... }) > 0 then
        msg = msg .. ' :: ' .. inspect({ ... })
    end

    ngx.log(level, '[metrix] ' .. msg)
end

local stderr = function(...)
    log(ngx.STDERR, ...)
end

local emerg = function(...)
    log(ngx.EMERG, ...)
end

local alert = function(...)
    log(ngx.ALERT, ...)
end

local crit = function(...)
    log(ngx.CRIT, ...)
end

local err = function(...)
    log(ngx.ERR, ...)
end

local warn = function(...)
    log(ngx.WARN, ...)
end

local notice = function(...)
    log(ngx.NOTICE, ...)
end

local info = function(...)
    log(ngx.INFO, ...)
end

local debug = function(...)
    log(ngx.DEBUG, ...)
end

local exports = {}
exports.log = log
exports.stderr = stderr
exports.stderror = stderr
exports.emerg = emerg
exports.emergency = emerg
exports.alert = alert
exports.crit = crit
exports.critical = crit
exports.err = err
exports.error = err
exports.warn = warn
exports.warning = warn
exports.notice = notice
exports.info = info
exports.debug = debug

return exports
