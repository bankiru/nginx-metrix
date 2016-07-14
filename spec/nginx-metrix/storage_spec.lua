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

    local result = storage(options_emu)

    assert.spy(storage.init).was_called_with(options_emu)
    assert.is_equal(storage, result)

    storage.init:revert()
  end)

  it('init failed on wrong shared_dict name', function()
    _G.ngx = { shared = {} }
    assert.has_error(function()
      storage.init({ shared_dict = 'non-existent-shared-dict' })
    end,
      'lua_shared_dict "non-existent-shared-dict" does not defined.')
  end)

  it('init failed on invalid shared_dict type', function()
    assert.has_error(function()
      storage.init({ shared_dict = 123123123 })
    end,
      'Invalid shared_dict type. Expected string or table, got number.')
  end)

  it('init by shared_dict instance', function()
    local shared_dict = {}

    assert.has_no.errors(function()
      storage.init({ shared_dict = shared_dict })
    end)

    assert.is_table(storage._shared_dict)
    assert.is_same(storage._shared_dict, shared_dict)

    local metatable = getmetatable(storage)
    assert.is_table(metatable)
    assert.is_function(metatable.__index)
  end)

  it('init by name', function()
    _G.ngx = { shared = { testdict = {} } }

    assert.has_no.errors(function()
      storage.init({ shared_dict = 'testdict' })
    end)

    assert.is_table(storage._shared_dict)

    local metatable = getmetatable(storage)
    assert.is_table(metatable)
    assert.is_function(metatable.__index)
  end)

  it('normalize key', function()
    assert.has_error(function()
      storage._normalize_key(nil)
    end,
      'key can not be nil')

    local normalized_key

    normalized_key = storage._normalize_key(777)
    assert.is_string(normalized_key)
    assert.are.equal(normalized_key, '777')

    normalized_key = storage._normalize_key({})
    assert.is_string(normalized_key)
    assert.matches('table: 0?x?[0-9a-f]+', normalized_key)
  end)

  it('non existent method', function()
    assert.has_error(function()
      storage.non_existent_method()
    end,
      "Method 'non_existent_method' does not exists in nginx shared dict.")
  end)

  it('simple proxy method call to nginx shared dict', function()
    local shared_dict_bak = storage._shared_dict

    storage._shared_dict = mock({ some_method = function() end })

    assert.has_no_error(function()
      storage.some_method('arg')
    end)

    assert.spy(storage._shared_dict.some_method).was_called_with(storage._shared_dict, 'arg')
    assert.spy(storage._shared_dict.some_method).was_called(1)

    storage._shared_dict = shared_dict_bak
  end)
end)
