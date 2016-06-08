local logger = require 'nginx-metrix.logger'
local dict = require 'nginx-metrix.storage.dict'
local namespaces = require 'nginx-metrix.storage.namespaces'

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

local process = function(collectors_list, namespaces_list, worker_id)
  local col_count = length(collectors_list)
  local ns_count = length(namespaces_list)

  if col_count == 0 then
    logger.debug(("[scheduler #%s] collectors list is empty, skipping"):format(worker_id))
    return
  end

  if ns_count == 0 then
    logger.debug(("[scheduler #%s] namespaces list is empty, skipping"):format(worker_id))
    return
  end

  if not setup_lock() then
    logger.debug(("[scheduler #%s] lock still exists, skipping"):format(worker_id))
    return
  end

  logger.debug(("[scheduler #%s] lock obtained, aggregating"):format(worker_id))

  local col_ns_thread_iter = take(
    col_count * ns_count,
    tabulate(function(x)
      local collector = collectors_list[operator.intdiv(x, ns_count) + 1]
      local namespace = namespaces_list[operator.mod(x, ns_count) + 1]
      local thread = ngx.thread.spawn(function()
        logger.debug(("[scheduler #%s] thread processing started for Collector<%s> on namespace '%s'"):format(worker_id, collector.name, namespace))
        namespaces.activate(namespace)
        collector:aggregate()
        logger.debug(("[scheduler #%s] thread processing finished for Collector<%s> on namespace '%s'"):format(worker_id, collector.name, namespace))
      end)
      logger.debug(("[scheduler #%s] spawned thread for Collector<%s> on namespace '%s'"):format(worker_id, collector.name, namespace))
      return collector, namespace, thread
    end)
  )

  col_ns_thread_iter:each(function(collector, namespace, thread)
    local ok, res = ngx.thread.wait(thread)
    if not ok then
      logger.error(("[scheduler #%s] failed to run Collector<%s>:aggregate() on namespace '%s'"):format(worker_id, collector.name, namespace), res)
    else
      logger.debug(("[scheduler #%s] thread finished for Collector<%s> on namespace '%s'"):format(worker_id, collector.name, namespace))
    end
  end)
end

local handler
handler = function(premature, collectors_list, worker_id)
  if premature then
    logger.debug(("[scheduler #%s] exited by premature flag"):format(worker_id))
    return
  end

  local ok, err

  process(collectors_list, namespaces.list(), worker_id)

  ok, err = ngx.timer.at(delay, handler, collectors_list, worker_id)
  if not ok then
    logger.error(("[scheduler #%s] Failed to continue the scheduler - failed to create the timer"):format(worker_id), err)
    return
  end
end

---
-- @return bool
local start = function()
  local worker_id = ngx.worker.id()

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
