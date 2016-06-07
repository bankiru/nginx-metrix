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

local delay = 1

local lock_key = '--scheduler-lock--'
local lock_timeout = delay * 0.95

local setup_lock = function()
  return (dict.add(lock_key, lock_key, lock_timeout))
end

local process = function(collectors_list, worker_id)
  if length(collectors_list) == 0 then
    logger.debug(("[scheduler #%s] collectors list is empty, skipping"):format(worker_id))
    return
  end

  if not setup_lock() then
    logger.debug(("[scheduler #%s] lock still exists, skipping"):format(worker_id))
    return
  end

  logger.debug(("[scheduler #%s] lock obtained, aggregating"):format(worker_id))
  iter(collectors_list):map(
    function(collector)
      logger.debug(("[scheduler #%s] spawned thread for Collector<%s>"):format(worker_id, collector.name))
      return collector, ngx.thread.spawn(function()
        logger.debug(("[scheduler #%s] thread processing started for Collector<%s>"):format(worker_id, collector.name))
        collector:aggregate()
        logger.debug(("[scheduler #%s] thread processing finished for Collector<%s>"):format(worker_id, collector.name))
      end)
    end
  ):each(
    function(collector, thread)
      local ok, res = ngx.thread.wait(thread)
      if not ok then
        logger.error(("[scheduler #%s] failed to run Collector<%s>:aggregate()"):format(worker_id, collector.name), res)
      else
        logger.debug(("[scheduler #%s] thread finished for Collector<%s>"):format(worker_id, collector.name))
      end
    end
  )
end

local handler
handler = function(premature, collectors_list, worker_id)
  if premature then
    logger.debug(("[scheduler #%s] exited by premature flag"):format(worker_id))
    return
  end

  local ok, err

  process(collectors_list, worker_id)

  ok, err = ngx.timer.at(delay, handler, collectors_list, worker_id)
  if not ok then
    logger.error(("[scheduler #%s] Failed to continue the scheduler - failed to create the timer"):format(worker_id), err)
    return
  end
end

---
-- @return bool
local start = function()
  local worker_id, incr_err = dict.safe_incr('worker_id')
  if incr_err ~= nil then
    logger.error('Can not make worker_id', incr_err)
    return false
  end

  logger.debug(('[scheduler #%s] starting'):format(worker_id))

  local ok, err = ngx.timer.at(delay, handler, collectors, worker_id)
  if not ok then
    logger.error(("[scheduler #%s] Failed to start the scheduler - failed to create the timer"):format(worker_id), err)
    return false
  end

  logger.debug(('[scheduler #%s] started'):format(worker_id))
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
    collectors = function() return collectors end,
    delay = function(value) if value == nil then return delay else delay = value end end,
    lock_key = function(value) if value == nil then return lock_key else lock_key = value end end,
    lock_timeout = function(value) if value == nil then return lock_timeout else lock_timeout = value end end,
    process = function(...) return process(...) end,
    handler = handler,
    setup_lock = setup_lock,
    _process = function(body) process = body end,
  }
end

return exports
