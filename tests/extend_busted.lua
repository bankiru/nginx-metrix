local s = require('say') --our i18n lib, installed through luarocks, included as a luassert dependency

local M = {
    assertions = {}
}

local function table_includes(container, contained)
    if container == contained then return true end
    local t1,t2 = type(container), type(contained)
    if t1 ~= t2 then return false end

    if t1 == 'table' then
        for k,v in pairs(contained) do
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
                    if M.assertions.table_equals(nil, {value, element}) then
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
        for k,v in pairs(actual) do
            if not table_contains(expected, v) then
                return false
            end
        end
        for k,v in pairs(expected) do
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

local function is_callable (obj)
    return type(obj) == 'function' or getmetatable(obj) and getmetatable(obj).__call and true
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

-- a special syntax sugar to export all functions to the global table
setmetatable(M, {
    __call = function(t, assert)
        for a_name, a_func in pairs(t.assertions) do
            assert:register("assertion", a_name, a_func, "assertion."..a_name..".positive", "assertion."..a_name..".negative")
        end
    end,
})

return M

