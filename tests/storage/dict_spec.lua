require('tests.bootstrap')(assert)

describe('storage.dict', function()
  local dict
  local logger
  local match

  local mk_test_dict = function()
    local shared_dict = mock({});
    dict.init({shared_dict = shared_dict})
    return shared_dict
  end

  setup(function()
    match = require 'luassert.match'
    logger = mock(require 'nginx-metrix.logger', true)
    dict = require 'nginx-metrix.storage.dict'
  end)

  teardown(function()
    package.loaded['nginx-metrix.logger'] = nil
    package.loaded['nginx-metrix.storage.dict'] = nil
  end)

  before_each(function()
  end)

  after_each(function()
    mock.clear(logger)
    _G.ngx = nil
  end)

  it('init failed on wrong shared_dict name', function()
    _G.ngx = {shared = {}}
    assert.has_error(
      function()
        dict.init({shared_dict = 'non-existent-shared-dict'})
      end,
      'lua_shared_dict "non-existent-shared-dict" does not defined.'
    )
  end)

  it('init failed on invalid shared_dict type', function()
    assert.has_error(
      function()
        dict.init({shared_dict = 123123123})
      end,
      'Invalid shared_dict type. Expected string or table, got number.'
    )
  end)

  it('init by shared_dict instance', function()
    local shared_dict = {}

    assert.has_no.errors(function()
      dict.init({shared_dict = shared_dict})
    end)

    assert.is_table(dict._shared)
    assert.is_same(dict._shared, shared_dict)

    local metatable = getmetatable(dict)
    assert.is_table(metatable)
    assert.is_function(metatable.__index)
  end)

  it('init by name', function()
    _G.ngx = {shared = {testdict = {}}}

    assert.has_no.errors(function()
      dict.init({shared_dict = 'testdict'})
    end)

    assert.is_table(dict._shared)

    local metatable = getmetatable(dict)
    assert.is_table(metatable)
    assert.is_function(metatable.__index)
  end)

  it('normalize key', function()
    assert.has_error(
      function()
        dict.__private__.normalize_key(nil)
      end,
      'key can not be nil'
    )

    local normalized_key

    normalized_key = dict.__private__.normalize_key(777)
    assert.is_string(normalized_key)
    assert.are.equal(normalized_key, '777')

    normalized_key = dict.__private__.normalize_key({})
    assert.is_string(normalized_key)
    assert.matches('table: 0?x?[0-9a-f]+', normalized_key)
  end)

  it('non existent method', function()
    assert.has_error(
      function()
        dict.non_existent_method()
      end,
      "attempt to call field 'non_existent_method' (a nil value)"
    )
    assert.spy(logger.error).was.called_with("dict method 'non_existent_method' does not exists")
    assert.spy(logger.error).was_called(1)
  end)

  it('get', function()
    local test_key = 'get-test-key'
    local test_value = 'get-test-value'

    local shared_dict = mk_test_dict('get')
    stub.new(shared_dict, 'get').on_call_with(shared_dict, test_key).returns(test_value, nil)

    local actual_value, actual_flags = dict.get(test_key)
    assert.spy(shared_dict.get).was.called_with(shared_dict, test_key)
    assert.spy(shared_dict.get).was_called(1)
    assert.are.equal(test_value, actual_value)
    assert.are.equal(0, actual_flags)
  end)

  it('get_stale', function()
    local test_key = 'get_stale-test-key'
    local test_value = 'get_stale-test-value'

    local shared_dict = mk_test_dict()
    stub.new(shared_dict, 'get_stale').on_call_with(shared_dict, test_key).returns(test_value, nil, false)

    local actual_value, actual_flags, actual_stale = dict.get_stale(test_key)
    assert.spy(shared_dict.get_stale).was_called_with(shared_dict, test_key)
    assert.spy(shared_dict.get_stale).was_called(1)
    assert.are.equal(test_value, actual_value)
    assert.are.equal(0, actual_flags)
    assert.is_false(actual_stale)
  end)

  it('set', function()
    local test_key = 'set-test-key'
    local test_value = 'set-test-value'

    local shared_dict = mk_test_dict()
    stub.new(shared_dict, 'set').on_call_with(shared_dict, test_key, test_value, 0, 0).returns(true, nil, false)

    local success, err, forcible = dict.set(test_key, test_value)
    assert.spy(shared_dict.set).was_called(1)
    assert.spy(shared_dict.set).was.called_with(shared_dict, test_key, test_value, 0, 0)
    assert.is_true(success)
    assert.is_nil(err)
    assert.is_false(forcible)
  end)

  it('safe_set', function()
    local test_key = 'safe_set-test-key'
    local test_value = 'safe_set-test-value'

    local shared_dict = mk_test_dict()
    stub.new(shared_dict, 'safe_set').on_call_with(shared_dict, test_key, test_value, 0, 0).returns(true, nil)

    local success, err = dict.safe_set(test_key, test_value)
    assert.spy(shared_dict.safe_set).was_called(1)
    assert.spy(shared_dict.safe_set).was.called_with(shared_dict, test_key, test_value, 0, 0)
    assert.is_true(success)
    assert.is_nil(err)
  end)

  it('add', function()
    local test_key = 'add-test-key'
    local test_value = 'add-test-value'

    local shared_dict = mk_test_dict()
    stub.new(shared_dict, 'add').on_call_with(shared_dict, test_key, test_value, 0, 0).returns(true, nil, false)

    local success, err, forcible = dict.add(test_key, test_value)
    assert.spy(shared_dict.add).was_called(1)
    assert.spy(shared_dict.add).was.called_with(shared_dict, test_key, test_value, 0, 0)
    assert.is_true(success)
    assert.is_nil(err)
    assert.is_false(forcible)
  end)

  it('safe_add', function()
    local test_key = 'safe_add-test-key'
    local test_value = 'safe_add-test-value'

    local shared_dict = mk_test_dict()
    stub.new(shared_dict, 'safe_add').on_call_with(shared_dict, test_key, test_value, 0, 0).returns(true, nil)

    local success, err = dict.safe_add(test_key, test_value)
    assert.spy(shared_dict.safe_add).was_called(1)
    assert.spy(shared_dict.safe_add).was.called_with(shared_dict, test_key, test_value, 0, 0)
    assert.is_true(success)
    assert.is_nil(err)
  end)

  it('incr failed with not found', function()
    local test_key = 'incr-test-key'
    local test_value = 13

    local shared_dict = mk_test_dict()
    stub.new(shared_dict, 'incr').on_call_with(shared_dict, test_key, test_value).returns(false, 'not found')

    local newval, err = dict.incr(test_key, test_value)
    assert.spy(shared_dict.incr).was_called(1)
    assert.spy(shared_dict.incr).was.called_with(shared_dict, test_key, test_value)
    assert.is_false(newval)
    assert.is_equal('not found', err)
  end)

  it('incr', function()
    local test_key = 'incr-test-key'
    local test_value = 7

    local shared_dict = mk_test_dict()
    stub.new(shared_dict, 'incr').on_call_with(shared_dict, test_key, test_value).returns(8, nil)

    local newval, err = dict.incr(test_key, test_value)
    assert.spy(shared_dict.incr).was_called(1)
    assert.spy(shared_dict.incr).was.called_with(shared_dict, test_key, test_value)
    assert.is_equal(8, newval)
    assert.is_nil(err)
  end)

  it('safe_incr', function()
    local test_key = 'safe_incr-test-key'

    local shared_dict = mk_test_dict()
    stub.new(shared_dict, 'incr').on_call_with(match._, test_key, 1).returns(false, 'not found')
    stub.new(shared_dict, 'add').on_call_with(shared_dict, test_key, 1, 0, 0).returns(true, nil)

    local newval, err

    newval, err = dict.safe_incr(test_key, 1)
    assert.spy(shared_dict.incr).was.called_with(shared_dict, test_key, 1)
    assert.spy(shared_dict.add).was.called_with(shared_dict, test_key, 1, 0, 0)
    assert.spy(shared_dict.incr).was.called(1)
    assert.spy(shared_dict.add).was.called(1)
    assert.are.equal(1, newval)
    assert.is_nil(err)
    mock.clear(shared_dict)

    stub.new(shared_dict, 'incr').on_call_with(shared_dict, test_key, 2).returns(3, nil)
    newval, err = dict.safe_incr(test_key, 2)
    assert.spy(shared_dict.incr).was.called_with(shared_dict, test_key, 2)
    assert.are.equal(3, newval)
    assert.is_nil(err)

    assert.spy(shared_dict.incr).was.called(1)
    assert.spy(shared_dict.add).was_not.called()
    mock.clear(shared_dict)
  end)

  it('replace failed with not found', function()
    local test_key = 'replace-test-key'
    local test_value = 13

    local shared_dict = mk_test_dict()
    stub.new(shared_dict, 'replace').on_call_with(shared_dict, test_key, test_value, 0, 0).returns(false, 'not found', nil)

    local success, err, forcible = dict.replace(test_key, test_value)
    assert.spy(shared_dict.replace).was_called(1)
    assert.spy(shared_dict.replace).was.called_with(shared_dict, test_key, test_value, 0, 0)
    assert.is_false(success)
    assert.is_equal('not found', err)
    assert.is_nil(forcible)
  end)

  it('replace', function()
    local test_key = 'replace-test-key'
    local test_value = 7

    local shared_dict = mk_test_dict()
    stub.new(shared_dict, 'replace').on_call_with(shared_dict, test_key, test_value, 0, 0).returns(true, nil, false)

    local success, err, forcible = dict.replace(test_key, test_value)
    assert.spy(shared_dict.replace).was_called(1)
    assert.spy(shared_dict.replace).was.called_with(shared_dict, test_key, test_value, 0, 0)
    assert.is_true(success)
    assert.is_nil(err)
    assert.is_false(forcible)
  end)

  it('delete', function()
    local test_key = 'delete-test-key'

    local shared_dict = mk_test_dict()
    stub.new(shared_dict, 'delete')

    dict.delete(test_key)
    assert.spy(shared_dict.delete).was_called(1)
    assert.spy(shared_dict.delete).was.called_with(shared_dict, test_key)
  end)

  it('flush_all', function()
    local shared_dict = mk_test_dict()

    stub.new(shared_dict, 'flush_all')
    dict.flush_all()
    assert.spy(shared_dict.flush_all).was.called(1)
  end)

  it('flush_expired', function()
    local shared_dict = mk_test_dict()

    stub.new(shared_dict, 'flush_expired')
    dict.flush_expired()
    assert.spy(shared_dict.flush_expired).was.called(1)
  end)

  it('get_keys', function()
    local shared_dict = mk_test_dict()

    stub.new(shared_dict, 'get_keys')
    dict.get_keys()
    assert.spy(shared_dict.get_keys).was.called(1)
  end)
end)
