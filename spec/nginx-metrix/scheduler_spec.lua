require('spec.bootstrap')(assert)

describe('nginx-metrix.scheduler', function()
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

  it('attach_action', function()
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

  it('run_actions', function()
    pending('impelement it')
  end)

  it('_reschedule', function()
    pending('impelement it')
  end)

  it('run', function()
    pending('impelement it')
  end)
end)
