require('spec.bootstrap')(assert)

describe('nginx-metrix.scheduler', function()
  local match = require 'luassert.match'

  local scheduler

  setup(function()
    scheduler = require 'nginx-metrix.scheduler'
  end)

  ---------------------------------------------------------------------------
  it('__call', function()
    stub(scheduler, 'init')
    local options_emu = { some_option = 'some_value' }
    local storage_emu = { 'storage' }

    local result = scheduler(options_emu, storage_emu)

    assert.spy(scheduler.init).was_called_with(options_emu, storage_emu)
    assert.is_equal(scheduler, result)

    scheduler.init:revert()
  end)

  it('init failed on invalid "scheduler_delay" type', function()
    assert.has_error(function()
      scheduler.init({ scheduler_delay = 'invalid type' }, { 'storage' })
    end,
      'Option "scheduler_delay" must be integer. Got string.')
  end)

  it('init failed on "scheduler_delay" zero or subzero', function()
    assert.has_error(function()
      scheduler.init({ scheduler_delay = -1 }, { 'storage' })
    end,
      'Option "scheduler_delay" must be grater then 0. Got -1.')

    assert.has_error(function()
      scheduler.init({ scheduler_delay = 0 }, { 'storage' })
    end,
      'Option "scheduler_delay" must be grater then 0. Got 0.')
  end)

  it('init ok with scheduler_delay', function()
    scheduler._delay = 13

    assert.has_no_error(function()
      scheduler.init({ scheduler_delay = 7 })
    end)

    assert.is_equal(7, scheduler._delay)

    scheduler._delay = 1
  end)

  it('init ok with no scheduler_delay', function()
    scheduler._delay = 7

    assert.has_no_error(function()
      scheduler.init({})
    end)

    assert.is_equal(7, scheduler._delay)

    scheduler._delay = 1
  end)

  it('_setup_lock', function()
    local stub_storage = mock({ add = function() return true, 1, 2, 3 end })

    scheduler._storage = stub_storage
    assert.is_true(scheduler._setup_lock())
    assert.spy(stub_storage.add).was_called_with('--aggregator-lock--', 1, 0.95)
    assert.spy(stub_storage.add).was_called(1)
  end)

  it('attach_action failed on non callable', function()
    assert.has_error(function()
      scheduler.attach_action('aaaa', 'bbbb')
    end, 'Action `aaaa` must be callable. Got string.')
  end)

  it('attach_action OK', function()
    local test_action_1 = function() end
    assert.has_no_error(function()
      scheduler.attach_action('test_action_1', test_action_1)
    end)
    assert.is_equal(test_action_1, scheduler._actions['test_action_1'])

    local test_action_2 = setmetatable({}, { __call = function() end })
    assert.has_no_error(function()
      scheduler.attach_action('test_action_2', test_action_2)
    end)
    assert.is_equal(test_action_2, scheduler._actions['test_action_2'])
  end)

  it('_run_actions', function()
    local logger_bak = scheduler._logger
    scheduler._logger = mock({ err = function() end, debug = function() end })

    local actions_bak = scheduler._actions
    scheduler.attach_action('test_action_1', function() end)
    scheduler.attach_action('test_action_2', function() end)
    mock(scheduler._actions, true)
    scheduler._actions['test_action_1'].on_call_with().invokes(function() error('Test error') end)
    scheduler._actions['test_action_2'].on_call_with().returns(nil)

    scheduler._run_actions()

    assert.spy(scheduler._logger.debug).was_called_with(scheduler._logger, 'Started scheduled action `test_action_1`.')
    assert.spy(scheduler._logger.err).was_called_with(scheduler._logger, 'Failed scheduled action `test_action_1`.', match.matches('Test error$'))
    assert.spy(scheduler._logger.debug).was_called_with(scheduler._logger, 'Started scheduled action `test_action_2`.')
    assert.spy(scheduler._logger.debug).was_called_with(scheduler._logger, 'Finished scheduled action `test_action_2`.')
    assert.spy(scheduler._logger.debug).was_called(3)
    assert.spy(scheduler._logger.err).was_called(1)

    scheduler._actions = actions_bak
    scheduler._logger = logger_bak
  end)

  it('_reschedule failed', function()
    local logger_bak = scheduler._logger

    scheduler._logger = mock({ err = function() end })

    _G.ngx = mock({ timer = { at = function() end } }, true)
    _G.ngx.timer.at.on_call_with(scheduler._delay, scheduler.run).returns(false, 'Test error')

    local result

    assert.has_no_error(function()
      result = scheduler._reschedule(true)
    end)
    assert.spy(scheduler._logger.err).was_called_with(scheduler._logger, 'Failed to start - can not create the timer.', 'Test error')
    assert.is_false(result)

    assert.has_no_error(function()
      result = scheduler._reschedule(false)
    end)
    assert.spy(scheduler._logger.err).was_called_with(scheduler._logger, 'Failed to continue - can not create the timer.', 'Test error')
    assert.is_false(result)

    assert.spy(scheduler._logger.err).was_called(2)

    scheduler._logger = logger_bak
    _G.ngx = nil
  end)

  it('_reschedule OK', function()
    local logger_bak = scheduler._logger

    scheduler._logger = mock({ err = function() end })

    _G.ngx = mock({ timer = { at = function() end } }, true)
    _G.ngx.timer.at.on_call_with(scheduler._delay, scheduler.run).returns(true, nil)

    local result

    assert.has_no_error(function()
      result = scheduler._reschedule(true)
    end)
    assert.is_true(result)

    assert.has_no_error(function()
      result = scheduler._reschedule(false)
    end)
    assert.is_true(result)

    assert.spy(scheduler._logger.err).was_not_called()

    scheduler._logger = logger_bak
    _G.ngx = nil
  end)

  it('run first time (starting) but _reshedule failed', function()
    local logger_bak = scheduler._logger

    scheduler._logger = mock({ debug = function() end })

    stub(scheduler, '_setup_lock')
    scheduler._setup_lock.on_call_with().returns(true)

    stub(scheduler, '_run_actions')

    stub(scheduler, '_reschedule')
    scheduler._reschedule.on_call_with(true).returns(false)

    local result = scheduler.run()

    assert.is_false(result)
    assert.spy(scheduler._reschedule).was_called_with(true)
    assert.spy(scheduler._logger.debug).was_called_with(scheduler._logger, 'Starting.')
    assert.spy(scheduler._logger.debug).was_called(1)
    assert.spy(scheduler._run_actions).was_called(1)
    assert.spy(scheduler._reschedule).was_called(1)

    scheduler._setup_lock:revert()
    scheduler._reschedule:revert()
    scheduler._run_actions:revert()
    scheduler._logger = logger_bak
  end)

  it('run first time (starting) OK', function()
    local logger_bak = scheduler._logger

    scheduler._logger = mock({ debug = function() end })

    stub(scheduler, '_setup_lock')
    scheduler._setup_lock.on_call_with().returns(true)

    stub(scheduler, '_run_actions')

    stub(scheduler, '_reschedule')
    scheduler._reschedule.on_call_with(true).returns(true)

    local result = scheduler.run()

    assert.is_true(result)
    assert.spy(scheduler._reschedule).was_called_with(true)
    assert.spy(scheduler._logger.debug).was_called_with(scheduler._logger, 'Starting.')
    assert.spy(scheduler._logger.debug).was_called_with(scheduler._logger, 'Started.')
    assert.spy(scheduler._logger.debug).was_called(2)
    assert.spy(scheduler._run_actions).was_called(1)
    assert.spy(scheduler._reschedule).was_called(1)

    scheduler._setup_lock:revert()
    scheduler._reschedule:revert()
    scheduler._run_actions:revert()
    scheduler._logger = logger_bak
  end)

  it('run scheduled', function()
    local logger_bak = scheduler._logger

    scheduler._logger = mock({ debug = function() end })

    stub(scheduler, '_setup_lock')
    scheduler._setup_lock.on_call_with().returns(true)

    stub(scheduler, '_run_actions')

    stub(scheduler, '_reschedule')
    scheduler._reschedule.on_call_with(false).returns(true)

    local result = scheduler.run(false)

    assert.is_true(result)
    assert.spy(scheduler._reschedule).was_called_with(false)
    assert.spy(scheduler._logger.debug).was_not_called()
    assert.spy(scheduler._run_actions).was_called(1)
    assert.spy(scheduler._reschedule).was_called(1)

    scheduler._setup_lock:revert()
    scheduler._reschedule:revert()
    scheduler._run_actions:revert()
    scheduler._logger = logger_bak
  end)

  it('run scheduled but lock exists', function()
    local logger_bak = scheduler._logger

    scheduler._logger = mock({ debug = function() end })

    stub(scheduler, '_setup_lock')
    scheduler._setup_lock.on_call_with().returns(false)

    stub(scheduler, '_run_actions')

    stub(scheduler, '_reschedule')
    scheduler._reschedule.on_call_with(false).returns(true)

    local result = scheduler.run(false)

    assert.is_true(result)
    assert.spy(scheduler._reschedule).was_called_with(false)
    assert.spy(scheduler._logger.debug).was_called_with(scheduler._logger, 'Lock still exists, skipping run actions.')
    assert.spy(scheduler._run_actions).was_not_called()
    assert.spy(scheduler._reschedule).was_called(1)

    scheduler._setup_lock:revert()
    scheduler._reschedule:revert()
    scheduler._run_actions:revert()
    scheduler._logger = logger_bak
  end)

  it('run stopped on premature exit', function()
    local logger_bak = scheduler._logger

    scheduler._logger = mock({ debug = function() end })

    stub(scheduler, '_setup_lock')
    scheduler._setup_lock.on_call_with().returns(false)

    stub(scheduler, '_run_actions')

    stub(scheduler, '_reschedule')
    scheduler._reschedule.on_call_with(false).returns(true)

    local result = scheduler.run(true)

    assert.is_false(result)
    assert.spy(scheduler._logger.debug).was_called_with(scheduler._logger, 'Exited by premature flag.')
    assert.spy(scheduler._logger.debug).was_called(1)
    assert.spy(scheduler._setup_lock).was_not_called()
    assert.spy(scheduler._run_actions).was_not_called()
    assert.spy(scheduler._reschedule).was_not_called()

    scheduler._setup_lock:revert()
    scheduler._reschedule:revert()
    scheduler._run_actions:revert()
    scheduler._logger = logger_bak
  end)
end)
