require('tests.bootstrap')(assert)

describe('listener', function()

  local listener

  before_each(function()
    package.loaded['nginx-metrix.listener'] = nil
    listener = require 'nginx-metrix.listener'
  end)

  after_each(function()
    package.loaded['nginx-metrix.listener'] = nil
    _G.ngx = nil
  end)

  it('attach_collector failed on invalid collector', function()
    local collector = { name = 'invalid-collector', ngx_phases = { [[invalid phase]] } }
    assert.has_error(
      function()
        listener.attach_collector(collector)
      end,
      'Collector<invalid-collector>.ngx_phases[invalid phase] invalid, phase "invalid phase" does not exists'
    )
  end)

  it('attach_collector', function()
    local collector = { name = 'test-collector-attach', ngx_phases = { [[log]] } }
    assert.has_no.errors(function()
      listener.attach_collector(collector)
    end)

    assert.is_same({ collector }, listener.__private__.get_handlers().log)
  end)

  it('handle_phase failed on invalid phase', function()
    assert.has.error(
      function()
        listener.handle_phase('invalid_phase')
      end,
      'Invalid ngx phase "invalid_phase" (string)'
    )
  end)

  it('handle_phase with passed phase name', function()
    local collector = mock({
      name = 'test-collector',
      ngx_phases = { [[log]] },
      handle_ngx_phase = function() end
    })

    assert.has_no.errors(function()
      listener.attach_collector(collector)
      listener.handle_phase('log')
    end)

    assert.spy(collector.handle_ngx_phase).was.called_with(collector, 'log')
  end)

  it('handle_phase without passed phase name', function()
    local collector = mock({
      name = 'test-collector',
      ngx_phases = { [[log]] },
      handle_ngx_phase = function() end
    })

    _G.ngx = { get_phase = function() return 'log' end }

    assert.has_no.errors(function()
      listener.attach_collector(collector)
      listener.handle_phase()
    end)

    assert.spy(collector.handle_ngx_phase).was.called_with(collector, 'log')
  end)
end)
