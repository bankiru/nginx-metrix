local fun = require 'fun'
local Logger = require 'nginx-metrix.logger'
local validator = require 'nginx-metrix.validator'

local M = {}

M._delay = 1
M._logger = Logger('scheduler')
M._storage = nil
M._actions = {}

---
-- @param options
--
function M.init(options, storage)
  M._storage = storage

  if options.scheduler_delay ~= nil then
    validator.assert_number(options.scheduler_delay, ('Option "scheduler_delay" must be integer. Got %s.'):format(type(options.scheduler_delay)))
    validator.assert_grater(options.scheduler_delay, 0, ('Option "scheduler_delay" must be grater then 0. Got %s.'):format(options.scheduler_delay))

    M._delay = options.scheduler_delay
  end
end

---
--
function M._setup_lock()
  return (M._storage.add('--aggregator-lock--', 1, M._delay * 0.95))
end

---
-- @param name
-- @param action
--
function M.attach_action(name, action)
  validator.assert_callable(action, ('Action `%s` must be callable. Got %s.'):format(name, type(action)))
  M._actions[name] = action
end

---
--
function M._run_actions()
  -- TODO: run in separate threads???
  fun.iter(M._actions):each(function(name, action)
    xpcall(function()
      M._logger:debug(('Started scheduled action `%s`.'):format(name))
      action()
      M._logger:debug(('Finished scheduled action `%s`.'):format(name))
    end,
      function(err)
        M._logger:err(('Failed scheduled action `%s`.'):format(name), err)
      end)
  end)
end

function M._reschedule(is_starting)
  local ok, err = ngx.timer.at(M._delay, M.run)

  if not ok then
    M._logger:err(("Failed to %s - can not create the timer."):format(is_starting and 'start' or 'continue'), err)
  end

  return ok
end

---
-- @param premature
--
function M.run(premature)
  local is_starting = premature == nil

  if is_starting then
    M._logger:debug('Starting.')
  end

  if premature then
    M._logger:debug('Exited by premature flag.')
    return false
  end

  if M._setup_lock() then
    M._run_actions()
  else
    M._logger:debug('Lock still exists, skipping run actions.')
  end

  if not M._reschedule(is_starting) then
    return false
  end

  if is_starting then
    M._logger:debug('Started.')
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
