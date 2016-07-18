local Logger = require 'nginx-metrix.logger'
local fun = require 'fun'

local M = {}

M._delay = 1
M._logger = Logger('scheduler')
M._actions = {}

---
--
function M._worker_id()
  return ngx.worker.id()
end

---
-- @param options
--
function M.init(options)
  if options.scheduler_delay ~= nil then
    assert(type(options.scheduler_delay) == 'number', ('Option "scheduler_delay" must be integer. Got %s.'):format(type(options.scheduler_delay)))
    assert(options.scheduler_delay > 0, ('Option "scheduler_delay" must be grater then 0. Got %s.'):format(options.scheduler_delay))

    M._delay = options.scheduler_delay
  end
end

---
-- @param name
-- @param action
--
function M.attach_action(name, action)
  M._actions[name] = action
end

---
--
function M.run_actions()
  -- TODO: run in separate threads???
  fun.iter(M._actions):each(function(name, action)
    xpcall(function()
      M._logger:debug(('Started scheduled action `%s` on worker #%s'):format(name, M._worker_id()))
      action(M._worker_id())
      M._logger:debug(('Finished scheduled action `%s` on worker #%s'):format(name, M._worker_id()))
    end,
      function(err)
        M._logger:err(('Failed scheduled action `%s` on worker #%s'):format(name, M._worker_id()), err)
      end)
  end)
end

function M._reschedule(is_starting)
  local ok, err = ngx.timer.at(M._delay, M.run)

  if not ok then
    M._logger.error(("Failed to %s on worker #%s - failed to create the timer"):format(is_starting and 'start' or 'continue', M._worker_id()), err)
  end

  return ok
end

---
-- @param premature
--
function M.run(premature)
  local is_starting = premature == nil

  if is_starting then
    M._logger.debug(('Starting on worker #%s'):format(M._worker_id()))
  end

  if premature then
    M._logger.debug(("Exited on worker #%s by premature flag"):format(M._worker_id()))
    return false
  end

  M.run_actions()

  if not M._reschedule(is_starting) then
    return false
  end

  if is_starting then
    M._logger.debug(('Started on worker #%s'):format(M._worker_id()))
  end

  return true
end

------------------------------------------------------------------------------
return setmetatable(M, {
  __call = function(_, ...)
    M.init(...)
    return M
  end,
})
