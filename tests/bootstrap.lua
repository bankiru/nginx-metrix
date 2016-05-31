_G.__TEST__ = true

local _ = package.loaded['fun'] or require 'fun'()
require 'nginx-metrix.lib.is'()

local copy
copy = function(obj, seen)
  if type(obj) ~= 'table' then return obj end
  if seen and seen[obj] then return seen[obj] end
  local s = seen or {}
  local res = setmetatable({}, getmetatable(obj))
  s[obj] = res
  for k, v in pairs(obj) do res[copy(k, s)] = copy(v, s) end
  return res
end
_G.copy = copy

local s = require('say') --our i18n lib, installed through luarocks, included as a luassert dependency

local M = {
  assertions = {},
  matchers = {},
}

local function table_includes(container, contained)
  if container == contained then return true end
  local t1, t2 = type(container), type(contained)
  if t1 ~= t2 then return false end

  if t1 == 'table' then
    for k, v in pairs(contained) do
      if not table_includes(container[k], v) then return false end
    end
    return true
  end
  return false
end

local function table_contains(t, element)
  if t then
    for _, value in pairs(t) do
      if type(value) == type(element) then
        if type(element) == 'table' then
          -- if we wanted recursive items content comparison, we could use
          -- table_equals(v, expected) but one level of just comparing
          -- items is sufficient
          if M.assertions.table_equals(nil, { value, element }) then
            return true
          end
        else
          if value == element then
            return true
          end
        end
      end
    end
  end
  return false
end


local function table_equals(actual, expected)
  if type(actual) == 'table' and type(expected) == 'table' then
    for _, v in pairs(actual) do
      if not table_contains(expected, v) then
        return false
      end
    end
    for _, v in pairs(expected) do
      if not table_contains(actual, v) then
        return false
      end
    end
    return true
  elseif type(actual) ~= type(expected) then
    return false
  elseif actual == expected then
    return true
  end
  return false
end

local function is_callable(obj)
  return type(obj) == 'function' or getmetatable(obj) and getmetatable(obj).__call and true
end

local function json_equal(json1, json2)
  local json = require 'dkjson'
  local util = require 'luassert.util'

  if type(json1) == 'string' then
    json1 = json.decode(json1)
  end

  if type(json2) == 'string' then
    json2 = json.decode(json2)
  end

  return util.deepcompare(json1, json2, true)
end

s:set("assertion.fail.positive", "%s")
s:set("assertion.fail.negative", "%s")
M.assertions['fail'] = function(_) return false end

s:set("assertion.table_contains.positive", "Expected %s\n to contain \n%s")
s:set("assertion.table_contains.negative", "Expected %s\n to NOT contain \n%s")
M.assertions['table_contains'] = function(_, arguments) return table_contains(arguments[1], arguments[2]) end

s:set("assertion.table_equals.positive", "Expected %s\n to be equal with %s")
s:set("assertion.table_equals.negative", "Expected %s\n to be NOT equal with %s")
M.assertions['table_equals'] = function(_, arguments) return table_equals(arguments[1], arguments[2]) end

s:set("assertion.table_includes.positive", "Expected %s\n to include \n%s")
s:set("assertion.table_includes.negative", "Expected %s\n to NOT include \n%s")
M.assertions['table_includes'] = function(_, arguments) return table_includes(arguments[1], arguments[2]) end

s:set("assertion.is_callable.positive", "Expected %s to be callable")
s:set("assertion.is_callable.negative", "Expected %s to be NOT callable")
M.assertions['is_callable'] = function(_, arguments) return is_callable(arguments[1]) end

s:set("assertion.json_equal.positive", "Expected %s\n to be equal with %s")
s:set("assertion.json_equal.negative", "Expected %s\n to be NOT equal with %s")
M.assertions['json_equal'] = function(_, arguments) return json_equal(arguments[1], arguments[2]) end

M.matchers["json_equal"] = function(_, arguments)
  return function(value)
    local is_eq = json_equal(value, arguments[1])
    if not is_eq then
      local i = require 'inspect'
      print(i({ json1 = value, json2 = arguments[1] }))
    end
    return is_eq
  end
end

-- a special syntax sugar to export all functions to the global table
setmetatable(M, {
  __call = function(t, assert)
    for a_name, a_func in pairs(t.assertions) do
      assert:register("assertion", a_name, a_func, "assertion." .. a_name .. ".positive", "assertion." .. a_name .. ".negative")
    end
    for a_name, a_func in pairs(t.matchers) do
      assert:register("matcher", a_name, a_func)
    end
  end,
})

return M
