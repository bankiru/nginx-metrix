require('spec.bootstrap')(assert)

describe('nginx-metrix.storage', function()
  local storage

  setup(function()
    storage = require 'nginx-metrix.storage'
  end)

  ---------------------------------------------------------------------------
  it('__call', function()
    stub(storage, 'init')
    local options_emu = { some_option = 'some_value' }

    storage(options_emu)

    assert.spy(storage.init).was_called_with(options_emu)

    storage.init:revert()
  end)

  it('init', function()
    pending('Implement it')
  end)
end)
