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

  it('init', function()
    pending('impelement it')
  end)

  it('_worker_id', function()
    pending('impelement it')
  end)

  it('attach_action', function()
    pending('impelement it')
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
