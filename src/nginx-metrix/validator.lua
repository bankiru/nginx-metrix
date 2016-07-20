local inspect = require 'inspect'

local M = {}

function M.is_callable(value)
  return type(value) == 'function' or type(value) == 'table' and getmetatable(value) and M.is_callable(getmetatable(value).__call)
end

function M.assert_callable(value, message)
  assert(M.is_callable(value), message or ('Expected callable (function or table with __call). Got %s.'):format(inspect(value)))
end

function M.is_number(value)
  return type(value) == 'number'
end

function M.assert_number(value, message)
  assert(M.is_number(value), message or ('Expected number. Got %s.'):format(inspect(value)))
end

function M.is_grater(value, origin)
  M.assert_number(value)
  M.assert_number(origin)

  return value > origin
end

function M.assert_grater(value, origin, message)
  assert(M.is_grater(value, origin), message or ('Expected that `%s` must be grater then `%s`.'):format(tostring(value), tostring(origin)))
end

return M
