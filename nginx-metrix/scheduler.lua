local logger = require 'nginx-metrix.logger'
local dict = require 'nginx-metrix.storage.dict'

local collectors = {}

---
-- @param collector table
--
local attach_collector = function(collector)
  if is.callable(collector.aggregate) then
    table.insert(collectors, collector)
  end
end

local lock_key = '--aggregator-lock--'
local lock_timeout = 2

local get_lock = function()
  local lock_id = ngx.now()
  local success, _, _ = dict.add(lock_key, lock_id, lock_timeout)
  if success then
    return true, lock_id
  end
  return false, nil
end

local drop_lock = function(lock_id)
  if lock_id == dict.get(lock_key) then
    dict.delete(lock_key)
    return true
  end
  return false
end

local delay = 1

local handler
handler = function(premature, collectors_list)
  if premature then
    return
  end

  if length(collectors_list) > 0 then
    local lock_success, lock_id = get_lock()
    if lock_success then
      iter(collectors_list):map(
        function(collector)
          return collector, ngx.thread.spawn(function() collector:aggregate() end)
        end
      ):each(
        function(collector, thread)
          local ok, res = ngx.thread.wait(thread)
          if not ok then
            logger.error(("failed to run Collector<%s>:aggregate(): "):format(collector.name), res)
          end
        end
      )

      drop_lock(lock_id)
    end
  end

  local ok, err = ngx.timer.at(delay, handler, collectors_list)
  if not ok then
    logger.error("Failed to continue the scheduler - failed to create the timer: ", err)
    return
  end
end

---
-- @return bool
local start = function()
  local ok, err = ngx.timer.at(delay, handler, collectors)
  if not ok then
    logger.error("Failed to start the scheduler - failed to create the timer: ", err)
    return false
  end
  return true
end

--------------------------------------------------------------------------------
-- EXPORTS
--------------------------------------------------------------------------------
local exports = {}
exports.attach_collector = attach_collector
exports.start = start

if __TEST__ then
  exports.__private__ = {
    get_collectors = function() return collectors end,
    lock_key       = function(value) if value == nil then return lock_key else lock_key = value end end,
    lock_timeout   = function(value) if value == nil then return lock_timeout else lock_timeout = value end end,

    handler        = handler,
    get_lock       = get_lock,
    drop_lock      = drop_lock,
  }
end

return exports
