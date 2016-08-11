require('spec.bootstrap')(assert)

describe('nginx-metrix.storage', function()
  local storage

  setup(function()
    storage = require 'nginx-metrix.storage'
  end)

  after_each(function()
    storage._shared_dict = {}
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
    storage._shared_dict = mock({ some_method = function() end })

    assert.has_no_error(function()
      storage.some_method('arg')
    end)

    assert.spy(storage._shared_dict.some_method).was_called_with(storage._shared_dict, 'arg')
    assert.spy(storage._shared_dict.some_method).was_called(1)
  end)


  it('get', function()
    local test_key = 'get-test-key'
    local test_value = 'get-test-value'

    storage._shared_dict = mock({ get = function() end }, true)
    storage._shared_dict.get.on_call_with(storage._shared_dict, test_key).returns(test_value, nil)

    local actual_value, actual_flags = storage.get(test_key)

    assert.spy(storage._shared_dict.get).was.called_with(storage._shared_dict, test_key)
    assert.spy(storage._shared_dict.get).was_called(1)
    assert.are.equal(test_value, actual_value)
    assert.are.equal(0, actual_flags)
  end)

  it('get_stale', function()
    local test_key = 'get_stale-test-key'
    local test_value = 'get_stale-test-value'

    storage._shared_dict = mock({ get_stale = function() end }, true)
    storage._shared_dict.get_stale.on_call_with(storage._shared_dict, test_key).returns(test_value, nil, false)

    local actual_value, actual_flags, actual_stale = storage.get_stale(test_key)

    assert.spy(storage._shared_dict.get_stale).was_called_with(storage._shared_dict, test_key)
    assert.spy(storage._shared_dict.get_stale).was_called(1)
    assert.are.equal(test_value, actual_value)
    assert.are.equal(0, actual_flags)
    assert.is_false(actual_stale)
  end)

  it('set', function()
    local test_key = 'set-test-key'
    local test_value = 'set-test-value'

    storage._shared_dict = mock({ set = function() end }, true)
    storage._shared_dict.set.on_call_with(storage._shared_dict, test_key, test_value, 0, 0).returns(true, nil, false)

    local success, err, forcible = storage.set(test_key, test_value)

    assert.spy(storage._shared_dict.set).was.called_with(storage._shared_dict, test_key, test_value, 0, 0)
    assert.spy(storage._shared_dict.set).was_called(1)
    assert.is_true(success)
    assert.is_nil(err)
    assert.is_false(forcible)
  end)

  it('safe_set', function()
    local test_key = 'safe_set-test-key'
    local test_value = 'safe_set-test-value'

    storage._shared_dict = mock({ safe_set = function() end }, true)
    storage._shared_dict.safe_set.on_call_with(storage._shared_dict, test_key, test_value, 0, 0).returns(true, nil)

    local success, err = storage.safe_set(test_key, test_value)

    assert.spy(storage._shared_dict.safe_set).was_called(1)
    assert.spy(storage._shared_dict.safe_set).was.called_with(storage._shared_dict, test_key, test_value, 0, 0)
    assert.is_true(success)
    assert.is_nil(err)
  end)

  it('add', function()
    local test_key = 'add-test-key'
    local test_value = 'add-test-value'

    storage._shared_dict = mock({ add = function() end }, true)
    storage._shared_dict.add.on_call_with(storage._shared_dict, test_key, test_value, 0, 0).returns(true, nil, false)

    local success, err, forcible = storage.add(test_key, test_value)

    assert.spy(storage._shared_dict.add).was.called_with(storage._shared_dict, test_key, test_value, 0, 0)
    assert.spy(storage._shared_dict.add).was_called(1)
    assert.is_true(success)
    assert.is_nil(err)
    assert.is_false(forcible)
  end)

  it('safe_add', function()
    local test_key = 'safe_add-test-key'
    local test_value = 'safe_add-test-value'

    storage._shared_dict = mock({ safe_add = function() end }, true)
    storage._shared_dict.safe_add.on_call_with(storage._shared_dict, test_key, test_value, 0, 0).returns(true, nil)

    local success, err = storage.safe_add(test_key, test_value)

    assert.spy(storage._shared_dict.safe_add).was.called_with(storage._shared_dict, test_key, test_value, 0, 0)
    assert.spy(storage._shared_dict.safe_add).was_called(1)
    assert.is_true(success)
    assert.is_nil(err)
  end)

  it('incr failed with not found', function()
    local test_key = 'incr-test-key'
    local test_value = 13

    storage._shared_dict = mock({ incr = function() end }, true)
    storage._shared_dict.incr.on_call_with(storage._shared_dict, test_key, test_value).returns(false, 'not found')

    local newval, err = storage.incr(test_key, test_value)

    assert.spy(storage._shared_dict.incr).was.called_with(storage._shared_dict, test_key, test_value)
    assert.spy(storage._shared_dict.incr).was_called(1)
    assert.is_false(newval)
    assert.is_equal('not found', err)
  end)

  it('incr', function()
    local test_key = 'incr-test-key'
    local test_value = 7

    storage._shared_dict = mock({ incr = function() end }, true)
    storage._shared_dict.incr.on_call_with(storage._shared_dict, test_key, test_value).returns(8, nil)

    local newval, err = storage.incr(test_key, test_value)

    assert.spy(storage._shared_dict.incr).was.called_with(storage._shared_dict, test_key, test_value)
    assert.spy(storage._shared_dict.incr).was_called(1)
    assert.is_equal(8, newval)
    assert.is_nil(err)
  end)

  it('safe_incr', function()
    local test_key = 'safe_incr-test-key'

    local newval, err

    storage._shared_dict = mock({ incr = function() end, add = function() end }, true)
    storage._shared_dict.incr.on_call_with(storage._shared_dict, test_key, 1).returns(false, 'not found')
    storage._shared_dict.add.on_call_with(storage._shared_dict, test_key, 1, 0, 0).returns(true, nil)

    newval, err = storage.safe_incr(test_key, 1)

    assert.spy(storage._shared_dict.incr).was.called_with(storage._shared_dict, test_key, 1)
    assert.spy(storage._shared_dict.add).was.called_with(storage._shared_dict, test_key, 1, 0, 0)
    assert.spy(storage._shared_dict.incr).was.called(1)
    assert.spy(storage._shared_dict.add).was.called(1)
    assert.are.equal(1, newval)
    assert.is_nil(err)
    mock.clear(storage._shared_dict)


    storage._shared_dict = mock({ incr = function() end, add = function() end }, true)
    storage._shared_dict.incr.on_call_with(storage._shared_dict, test_key, 2).returns(3, nil)

    newval, err = storage.safe_incr(test_key, 2)

    assert.spy(storage._shared_dict.incr).was.called_with(storage._shared_dict, test_key, 2)
    assert.spy(storage._shared_dict.incr).was.called(1)
    assert.spy(storage._shared_dict.add).was_not.called()
    assert.is_nil(err)
    assert.are.equal(3, newval)
    mock.clear(storage._shared_dict)


    storage._shared_dict = mock({ incr = function() end, add = function() end }, true)
    storage._shared_dict.incr.on_call_with(storage._shared_dict, test_key, 13).returns(nil, 'unhandled error')

    newval, err = storage.safe_incr(test_key, 13)

    assert.spy(storage._shared_dict.incr).was.called_with(storage._shared_dict, test_key, 13)
    assert.spy(storage._shared_dict.incr).was.called(1)
    assert.spy(storage._shared_dict.add).was_not.called()
    assert.is_nil(newval)
    assert.are.equal('unhandled error', err)
    mock.clear(storage._shared_dict)
  end)

  it('replace failed with not found', function()
    local test_key = 'replace-test-key'
    local test_value = 13

    storage._shared_dict = mock({ replace = function() end }, true)
    storage._shared_dict.replace.on_call_with(storage._shared_dict, test_key, test_value, 0, 0).returns(false, 'not found', nil)

    local success, err, forcible = storage.replace(test_key, test_value)

    assert.spy(storage._shared_dict.replace).was.called_with(storage._shared_dict, test_key, test_value, 0, 0)
    assert.spy(storage._shared_dict.replace).was_called(1)
    assert.is_false(success)
    assert.is_equal('not found', err)
    assert.is_nil(forcible)
  end)

  it('replace', function()
    local test_key = 'replace-test-key'
    local test_value = 7

    storage._shared_dict = mock({ replace = function() end }, true)
    storage._shared_dict.replace.on_call_with(storage._shared_dict, test_key, test_value, 0, 0).returns(true, nil, false)

    local success, err, forcible = storage.replace(test_key, test_value)

    assert.spy(storage._shared_dict.replace).was.called_with(storage._shared_dict, test_key, test_value, 0, 0)
    assert.spy(storage._shared_dict.replace).was_called(1)
    assert.is_true(success)
    assert.is_nil(err)
    assert.is_false(forcible)
  end)

  it('delete', function()
    storage._shared_dict = mock({ delete = function() end })

    local test_key = 'delete-test-key'

    storage.delete(test_key)

    assert.spy(storage._shared_dict.delete).was_called_with(storage._shared_dict, test_key)
    assert.spy(storage._shared_dict.delete).was_called(1)
  end)

  it('flush_all', function()
    storage._shared_dict = mock({ flush_all = function() end })

    storage.flush_all()

    assert.spy(storage._shared_dict.flush_all).was_called_with(storage._shared_dict)
    assert.spy(storage._shared_dict.flush_all).was_called(1)
  end)

  it('flush_expired', function()
    storage._shared_dict = mock({ flush_expired = function() end })

    storage.flush_expired()

    assert.spy(storage._shared_dict.flush_expired).was_called_with(storage._shared_dict)
    assert.spy(storage._shared_dict.flush_expired).was_called(1)
  end)

  it('get_keys', function()
    storage._shared_dict = mock({ get_keys = function() end })

    storage.get_keys()

    assert.spy(storage._shared_dict.get_keys).was_called_with(storage._shared_dict)
    assert.spy(storage._shared_dict.get_keys).was_called(1)
  end)
end)
