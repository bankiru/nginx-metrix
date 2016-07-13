local fun = require 'fun'
local inspect = require 'inspect'

local M = {}
M.__index = M

function M.new(module_name)
  return setmetatable({module_name = module_name}, M)
end

function M:log(level, msg, ...)
    if type(msg) ~= 'string' then
        msg = inspect(msg)
    end

    if fun.length({ ... }) > 0 then
        msg = msg .. ' :: ' .. inspect({ ... })
    end

    ngx.log(level, ('[%s] %s'):format(self.module_name or 'nginx-metrix', msg))
end

function M:stderr(...)
  self:log(ngx.STDERR, ...)
end

function M:emerg(...)
    self:log(ngx.EMERG, ...)
end

function M:alert(...)
    self:log(ngx.ALERT, ...)
end

function M:crit(...)
    self:log(ngx.CRIT, ...)
end

function M:err(...)
    self:log(ngx.ERR, ...)
end

function M:warn(...)
    self:log(ngx.WARN, ...)
end

function M:notice(...)
    self:log(ngx.NOTICE, ...)
end

function M:info(...)
    self:log(ngx.INFO, ...)
end

function M:debug(...)
    self:log(ngx.DEBUG, ...)
end

return setmetatable(M, {
  __call = function(_, ...) return M.new(...) end,
})
