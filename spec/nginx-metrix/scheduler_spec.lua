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

    local result = scheduler(options_emu)

    assert.spy(scheduler.init).was_called_with(options_emu)
    assert.is_equal(scheduler, result)

    scheduler.init:revert()
  end)

  it('init failed on invalid "scheduler_delay" type', function()
    assert.has_error(function()
      scheduler.init({ scheduler_delay = 'invalid type' })
    end,
      'Option "scheduler_delay" must be integer. Got string.')
  end)

  it('init failed on "scheduler_delay" zero or subzero', function()
    assert.has_error(function()
      scheduler.init({ scheduler_delay = -1 })
    end,
      'Option "scheduler_delay" must be grater then 0. Got -1.')

    assert.has_error(function()
      scheduler.init({ scheduler_delay = 0 })
    end,
      'Option "scheduler_delay" must be grater then 0. Got 0.')
  end)

  it('init ok with scheduler_delay', function()
    scheduler._delay = 13

    assert.has_no_error(function()
      scheduler.init({ scheduler_delay = 7 })
    end)

    assert.is_equal(7, scheduler._delay)
  end)

  it('init ok with no scheduler_delay', function()
    scheduler._delay = 7

    assert.has_no_error(function()
      scheduler.init({})
    end)

    assert.is_equal(7, scheduler._delay)
  end)

  it('_worker_id', function()
    _G.ngx = mock({ worker = { id = function() return 'OOOOK' end } })
    local worker_id = scheduler._worker_id()
    assert.spy(ngx.worker.id).was_called_with()
    assert.spy(ngx.worker.id).was_called(1)
    assert.is_equal('OOOOK', worker_id)
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

    stub(scheduler, '_worker_id')
    scheduler._worker_id.on_call_with().returns(13)

    local actions_bak = scheduler._actions
    scheduler.attach_action('test_action_1', function() end)
    scheduler.attach_action('test_action_2', function() end)
    mock(scheduler._actions, true)
    scheduler._actions['test_action_1'].on_call_with(13).invokes(function() error('Test error') end)
    scheduler._actions['test_action_2'].on_call_with(13).returns(nil)

    scheduler._run_actions()

    assert.spy(scheduler._logger.debug).was_called_with(scheduler._logger, 'Started scheduled action `test_action_1` on worker #13')
    assert.spy(scheduler._logger.err).was_called_with(scheduler._logger, 'Failed scheduled action `test_action_1` on worker #13', match.matches('Test error$'))
    assert.spy(scheduler._logger.debug).was_called_with(scheduler._logger, 'Started scheduled action `test_action_2` on worker #13')
    assert.spy(scheduler._logger.debug).was_called_with(scheduler._logger, 'Finished scheduled action `test_action_2` on worker #13')
    assert.spy(scheduler._logger.debug).was_called(3)
    assert.spy(scheduler._logger.err).was_called(1)

    scheduler._actions = actions_bak
    scheduler._worker_id:revert()
    scheduler._logger = logger_bak
  end)

  it('_reschedule failed', function()
    local logger_bak = scheduler._logger

    scheduler._logger = mock({ err = function() end })

    stub(scheduler, '_worker_id')
    scheduler._worker_id.on_call_with().returns(7)

    _G.ngx = mock({ timer = { at = function() end } }, true)
    _G.ngx.timer.at.on_call_with(scheduler._delay, scheduler.run).returns(false, 'Test error')

    local result

    assert.has_no_error(function()
      result = scheduler._reschedule(true)
    end)
    assert.spy(scheduler._logger.err).was_called_with(scheduler._logger, 'Failed to start on worker #7 - failed to create the timer', 'Test error')
    assert.is_false(result)

    assert.has_no_error(function()
      result = scheduler._reschedule(false)
    end)
    assert.spy(scheduler._logger.err).was_called_with(scheduler._logger, 'Failed to continue on worker #7 - failed to create the timer', 'Test error')
    assert.is_false(result)

    assert.spy(scheduler._logger.err).was_called(2)
    assert.spy(scheduler._worker_id).was_called(2)

    scheduler._worker_id:revert()
    scheduler._logger = logger_bak
    _G.ngx = nil
  end)

  it('_reschedule OK', function()
    local logger_bak = scheduler._logger

    scheduler._logger = mock({ err = function() end })

    stub(scheduler, '_worker_id')
    scheduler._worker_id.on_call_with().returns(7)

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
    assert.spy(scheduler._worker_id).was_not_called()

    scheduler._worker_id:revert()
    scheduler._logger = logger_bak
    _G.ngx = nil
  end)

  it('run first time (starting) but _reshedule failed', function()
    local logger_bak = scheduler._logger

    scheduler._logger = mock({ debug = function() end })

    stub(scheduler, '_worker_id')
    scheduler._worker_id.on_call_with().returns(13)

    stub(scheduler, '_run_actions')

    stub(scheduler, '_reschedule')
    scheduler._reschedule.on_call_with(true).returns(false)

    local result = scheduler.run()

    assert.is_false(result)
    assert.spy(scheduler._reschedule).was_called_with(true)
    assert.spy(scheduler._logger.debug).was_called_with(scheduler._logger, 'Starting on worker #13')
    assert.spy(scheduler._worker_id).was_called(1)
    assert.spy(scheduler._logger.debug).was_called(1)
    assert.spy(scheduler._run_actions).was_called(1)
    assert.spy(scheduler._reschedule).was_called(1)

    scheduler._worker_id:revert()
    scheduler._reschedule:revert()
    scheduler._run_actions:revert()
    scheduler._logger = logger_bak
  end)

  it('run first time (starting) OK', function()
    local logger_bak = scheduler._logger

    scheduler._logger = mock({ debug = function() end })

    stub(scheduler, '_worker_id')
    scheduler._worker_id.on_call_with().returns(7)

    stub(scheduler, '_run_actions')

    stub(scheduler, '_reschedule')
    scheduler._reschedule.on_call_with(true).returns(true)

    local result = scheduler.run()

    assert.is_true(result)
    assert.spy(scheduler._reschedule).was_called_with(true)
    assert.spy(scheduler._logger.debug).was_called_with(scheduler._logger, 'Starting on worker #7')
    assert.spy(scheduler._logger.debug).was_called_with(scheduler._logger, 'Started on worker #7')
    assert.spy(scheduler._worker_id).was_called(2)
    assert.spy(scheduler._logger.debug).was_called(2)
    assert.spy(scheduler._run_actions).was_called(1)
    assert.spy(scheduler._reschedule).was_called(1)

    scheduler._worker_id:revert()
    scheduler._reschedule:revert()
    scheduler._run_actions:revert()
    scheduler._logger = logger_bak
  end)

  it('run scheduled', function()
    local logger_bak = scheduler._logger

    scheduler._logger = mock({ debug = function() end })

    stub(scheduler, '_worker_id')
    scheduler._worker_id.on_call_with().returns(8)

    stub(scheduler, '_run_actions')

    stub(scheduler, '_reschedule')
    scheduler._reschedule.on_call_with(false).returns(true)

    local result = scheduler.run(false)

    assert.is_true(result)
    assert.spy(scheduler._reschedule).was_called_with(false)
    assert.spy(scheduler._logger.debug).was_not_called()
    assert.spy(scheduler._worker_id).was_not_called()
    assert.spy(scheduler._run_actions).was_called(1)
    assert.spy(scheduler._reschedule).was_called(1)

    scheduler._worker_id:revert()
    scheduler._reschedule:revert()
    scheduler._run_actions:revert()
    scheduler._logger = logger_bak
  end)

  it('run stopped on premature exit', function()
    local logger_bak = scheduler._logger

    scheduler._logger = mock({ debug = function() end })

    stub(scheduler, '_worker_id')
    scheduler._worker_id.on_call_with().returns(9)

    stub(scheduler, '_run_actions')

    stub(scheduler, '_reschedule')
    scheduler._reschedule.on_call_with(false).returns(true)

    local result = scheduler.run(true)

    assert.is_false(result)
    assert.spy(scheduler._logger.debug).was_called_with(scheduler._logger, 'Exited on worker #9 by premature flag')
    assert.spy(scheduler._logger.debug).was_called(1)
    assert.spy(scheduler._worker_id).was_called(1)
    assert.spy(scheduler._run_actions).was_not_called()
    assert.spy(scheduler._reschedule).was_not_called()

    scheduler._worker_id:revert()
    scheduler._reschedule:revert()
    scheduler._run_actions:revert()
    scheduler._logger = logger_bak
  end)
end)
