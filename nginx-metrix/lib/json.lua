local json

for _, m in pairs({[[cjson]], [[json]]}) do
    local succ, _json = pcall(function() return require(m) end)
    if succ then
        json = _json
        break
    end
end

if json == nil then
    error('Can not find lua json or cjson')
end

return json