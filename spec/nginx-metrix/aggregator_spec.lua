require('spec.bootstrap')(assert)

describe('nginx-metrix.aggregator', function()
  local aggregator

  setup(function()
    aggregator = require 'nginx-metrix.aggregator'
  end)

  ---------------------------------------------------------------------------
  it('__call', function()
    stub(aggregator, 'init')
    local options_emu = { some_option = 'some_value' }
    local storage_emu = { 'storage' }

    local result = aggregator(options_emu, storage_emu)

    assert.spy(aggregator.init).was_called_with(options_emu, storage_emu)
    assert.is_equal(aggregator, result)

    aggregator.init:revert()
  end)

  it('init', function()
    pending('impelement it')
  end)

  it('aggregate', function()
    pending('impelement it')
  end)
end)
