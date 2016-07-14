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
    pending('implement it')
    --    assert.has_error(function()
    --      storage._normalize_key(nil)
    --    end,
    --      'key can not be nil')
    --
    --    local normalized_key
    --
    --    normalized_key = dict.__private__.normalize_key(777)
    --    assert.is_string(normalized_key)
    --    assert.are.equal(normalized_key, '777')
    --
    --    normalized_key = dict.__private__.normalize_key({})
    --    assert.is_string(normalized_key)
    --    assert.matches('table: 0?x?[0-9a-f]+', normalized_key)
  end)

  it('non existent method', function()
    pending('implement it')
    --    assert.has_error(function()
    --      dict.non_existent_method()
    --    end,
    --      "attempt to call field 'non_existent_method' (a nil value)")
    --    assert.spy(logger.error).was.called_with("dict method 'non_existent_method' does not exists")
    --    assert.spy(logger.error).was_called(1)
  end)
end)
