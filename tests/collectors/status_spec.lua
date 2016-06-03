require('tests.bootstrap')(assert)

describe('collectors.status', function()
  local collector

  setup(function()
    package.loaded['nginx-metrix.collectors.status'] = nil
    collector = require 'nginx-metrix.collectors.status'
  end)

  teardown(function()
    collector = nil
    package.loaded['nginx-metrix.collectors.status'] = nil
    _G.ngx = nil
  end)

  -- tests
  it('valid structure', function()
    assert.is_equal('status', collector.name)
    assert.is_table(collector.fields)
    assert.is_table(collector.ngx_phases)
    assert.is_function(collector.on_phase)
  end)

  it('handles phase log', function()
    assert.is_nil(collector.fields['499'])

    collector.storage = mock({ cyclic_incr = function() end }, true)
    _G.ngx = { status = 499 }
    collector:on_phase('log')

    assert.spy(collector.storage.cyclic_incr).was.called(1)
    assert.spy(collector.storage.cyclic_incr).was.called_with(collector.storage, 499)

    assert.is_table(collector.fields['499'])
  end)
end)
