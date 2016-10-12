local math = require 'math'
local storage_dict = require 'nginx-metrix.storage.dict'

math.randomseed(ngx and ngx.now() or os.time())

-- Window Item --
local WindowItem = {}
WindowItem.__index = WindowItem

---
--
function WindowItem.create_key()
  return ngx.md5(string.format('%.3f %.12f', ngx.now(), math.random()))
end

---
-- @param payload
--
function WindowItem.new(payload)
  local windowItem = setmetatable({ _key = WindowItem.create_key(), _payload = payload, _next = nil }, WindowItem)
  windowItem:store()
  return windowItem
end

---
-- @param self WindowItem
--
function WindowItem.store(self)
  return storage_dict.set('WindowItem^' .. self._key, self)
end

---
-- @param key
--
function WindowItem.restore(key)
  local data = storage_dict.get('WindowItem^' .. key)
  if data ~= nil then
    return setmetatable(data, WindowItem)
  end
  return nil
end

---
-- @param self
--
function WindowItem.key(self)
  return self._key
end

function WindowItem.payload(self)
  return self._payload
end

---
-- @param self
-- @param next
--
function WindowItem.next(self, next)
  if next ~= nil then
    self._next = next:key()
    self:store()
  elseif self._next == nil then
    return nil
  else
    next = WindowItem.restore(self._next)

    if next == nil then
      self._next = nil
      self:store()
    end

    return next
  end
end

-- /Window Item --

-- Window --
local Window = {}
Window.__index = Window

---
-- @param name
-- @param limit
--
function Window.open(name, limit)
  local window = (storage_dict.get('Window^' .. name)) or { _name = name, _limit = limit, _size = 0, _head = nil, _tail = nil }
  return setmetatable(window, Window)
end

---
-- @param self
--
function Window.store(self)
  return storage_dict.set('Window^' .. self._name, self)
end

function Window.size(self)
  return self._size
end

Window.len = Window.size

---
-- @param self
-- @param payload
--
function Window.push(self, payload)
  if self._limit == self._size then
    self:pop()
  end

  local item = WindowItem.new(payload)

  if self._tail ~= nil then
    WindowItem.restore(self._tail):next(item)
  end

  self._tail = item:key()
  if self._head == nil then
    self._head = self._tail
  end
  self._size = self._size + 1

  self:store()
end

---
-- @param self
--
function Window.pop(self)
  if self._head == nil then
    return nil
  end

  local head = WindowItem.restore(self._head)
  self._head = head._next
  if self._head == nil then
    self._tail = nil
  end
  self._size = self._size - 1

  self:store()

  return head:payload()
end

---
-- @param self
--
function Window.totable(self)
  local list = {}

  local item = self._head and WindowItem.restore(self._head)
  while item ~= nil do
    table.insert(list, item:payload())
    item = item:next()
  end

  return list;
end

-- /Window --

--------------------------------------------------------------------------------
-- EXPORTS
--------------------------------------------------------------------------------

local exports = Window

if __TEST__ then
  exports.__private__ = {
    WindowItem = WindowItem,
  }
end

return exports
