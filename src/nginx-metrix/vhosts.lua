local fun = require 'fun'

local M = {}

M._vhosts_storage_key = 'vhosts'
M._storage = nil
M._active_vhost = nil
M._vhosts = {}

---
-- @param options
-- @param storage
--
function M.init(options, storage)
  M._storage = storage

  if options.vhosts then
    assert(type(options.vhosts) == 'table', ('Invalid option `vhosts`. Expected table, got %s.'):format(type(options.vhosts)))

    M.add(options.vhosts)
  end
end

function M._restore()
  M._vhosts = M._storage.get(M._vhosts_storage_key)
  if type(M._vhosts) ~= 'table' then
    M._vhosts = {}
  end
end

function M._store()
  return M._storage.set(M._vhosts_storage_key, M._vhosts)
end

---
-- @param vhosts
--
function M.add(vhosts)
  assert(type(vhosts) == 'table' or type(vhosts) == 'string', ('Invalid argument for vhosts.add(). Expected table or string, got %s.'):format(type(vhosts)))

  if type(vhosts) == 'string' then
    vhosts = { vhosts }
  end

  -- check if vhost already exists in local cache
  if fun.all(function(vhost) return fun.index(vhost, M._vhosts) ~= nil end, vhosts) then
    return
  end

  -- load from storage
  M._restore()

  -- insert into cache if not exists
  fun.iter(vhosts):each(function(vhost)
    if fun.index(vhost, M._vhosts) == nil then
      table.insert(M._vhosts, vhost)
    end
  end)

  -- save to storage
  M._store()
end

---
-- @return table
---
function M.list()
  M._restore()

  return M._vhosts
end

---
-- @param vhost
---
function M.active(vhost)
  if vhost == nil then
    return M._active_vhost
  end

  assert(type(vhost) == 'string', ('Invalid argument for vhosts.active(). Expected string or nil, got %s.'):format(type(vhost)))

  M._active_vhost = vhost
  M.add(vhost)
end

---
--
function M.reset_active()
  M._active_vhost = nil
end


return setmetatable(M, {
  __call = function(_, ...)
    M.init(...)
    return M
  end,
})
