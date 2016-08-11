local inspect = require 'inspect'

local M = {}

function M.is_callable(value)
  return type(value) == 'function' or type(value) == 'table' and getmetatable(value) and M.is_callable(getmetatable(value).__call) or false
end

function M.assert_callable(value, message)
  assert(M.is_callable(value), message or ('Expected callable (function or table with __call). Got %s.'):format(inspect(value)))
end

function M.is_type(expected_type, value)
  return type(value) == expected_type
end

function M.assert_type(expected_type, value, message)
  assert(M.is_type(expected_type, value), message or ('Expected %s. Got %s.'):format(expected_type, inspect(value)))
end

function M.is_number(value)
  return M.is_type('number', value)
end

function M.assert_number(value, message)
  M.assert_type('number', value, message)
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
