require('tests.bootstrap')(assert)

describe('storage.collector_wrapper_factory', function()
  local match

  local namespaces
  local dict_mock
  local factory
  local Window

  local mk_wrapper_metatable_mock = function(name)
    local wrapper_metatable = copy(factory.__private__.wrapper_metatable)
    if name ~= nil then
      wrapper_metatable.collector_name = 'collector_mock'
    end
    return wrapper_metatable
  end

  setup(function()
    match = require 'luassert.match'

    package.loaded['nginx-metrix.storage.dict'] = nil
    dict_mock = mock(require 'nginx-metrix.storage.dict', true)
    package.loaded['nginx-metrix.storage.dict'] = dict_mock

    package.loaded['nginx-metrix.storage.namespaces'] = nil
    namespaces = require 'nginx-metrix.storage.namespaces'

    package.loaded['nginx-metrix.storage.window'] = nil
    Window = require 'nginx-metrix.storage.window'

    package.loaded['nginx-metrix.storage.collector_wrapper_factory'] = nil
    factory = require 'nginx-metrix.storage.collector_wrapper_factory'
  end)

  teardown(function()
    mock.revert(dict_mock)
    package.loaded['nginx-metrix.storage.dict'] = nil
    package.loaded['nginx-metrix.storage.window'] = nil

    package.loaded['nginx-metrix.storage.collector_wrapper_factory'] = nil
  end)

  after_each(function()
    namespaces.reset_active()
    mock.clear(dict_mock)
    _G.ngx = nil
  end)

  it('create', function()
    local collector_mock = { name = 'collector_mock' }

    local wrapper
    assert.has_no.errors(function()
      wrapper = factory.create(collector_mock)
    end)

    assert.is_table(wrapper)
    assert.is_equal(collector_mock.name, wrapper.collector_name)
    assert.is_same(factory.__private__.wrapper_metatable, getmetatable(wrapper))
  end)

  it('wrapper_metatable.prepare_key failed with nil key', function()
    local wrapper_metatable = mk_wrapper_metatable_mock()

    assert.has_error(function()
      wrapper_metatable:prepare_key(nil)
    end,
      'key can not be nil')
  end)

  it('wrapper_metatable.prepare_key', function()
    local wrapper_metatable = mk_wrapper_metatable_mock()

    local actual_value

    actual_value = wrapper_metatable:prepare_key('test-key-1')
    assert.is_equal('test-key-1', actual_value)

    wrapper_metatable.collector_name = 'collector_mock'

    actual_value = wrapper_metatable:prepare_key('test-key-2')
    assert.is_equal('collector_mock¦test-key-2', actual_value)

    namespaces.activate('test-namespace')
    actual_value = wrapper_metatable:prepare_key('test-key-3')
    assert.is_equal('test-namespaceːcollector_mock¦test-key-3', actual_value)
  end)

  it('wrapper_metatable.get', function()
    local wrapper_metatable = mk_wrapper_metatable_mock('collector-mock')

    wrapper_metatable:get('test-key')
    assert.spy(dict_mock.get).was.called_with('collector_mock¦test-key')
  end)

  it('wrapper_metatable.get_stale', function()
    local wrapper_metatable = mk_wrapper_metatable_mock('collector-mock')

    wrapper_metatable:get_stale('test-key')
    assert.spy(dict_mock.get_stale).was.called_with('collector_mock¦test-key')
  end)

  it('wrapper_metatable.set', function()
    local wrapper_metatable = mk_wrapper_metatable_mock('collector-mock')

    wrapper_metatable:set('test-key', 1, 1313, 13)
    assert.spy(dict_mock.set).was.called_with('collector_mock¦test-key', 1, 1313, 13)
  end)

  it('wrapper_metatable.safe_set', function()
    local wrapper_metatable = mk_wrapper_metatable_mock('collector-mock')

    wrapper_metatable:safe_set('test-key', 1, 1313, 13)
    assert.spy(dict_mock.safe_set).was.called_with('collector_mock¦test-key', 1, 1313, 13)
  end)

  it('wrapper_metatable.add', function()
    local wrapper_metatable = mk_wrapper_metatable_mock('collector-mock')

    wrapper_metatable:add('test-key', 1, 1313, 13)
    assert.spy(dict_mock.add).was.called_with('collector_mock¦test-key', 1, 1313, 13)
  end)

  it('wrapper_metatable.safe_add', function()
    local wrapper_metatable = mk_wrapper_metatable_mock('collector-mock')

    wrapper_metatable:safe_add('test-key', 1, 1313, 13)
    assert.spy(dict_mock.safe_add).was.called_with('collector_mock¦test-key', 1, 1313, 13)
  end)

  it('wrapper_metatable.replace', function()
    local wrapper_metatable = mk_wrapper_metatable_mock('collector-mock')

    wrapper_metatable:replace('test-key', 1, 1313, 13)
    assert.spy(dict_mock.replace).was.called_with('collector_mock¦test-key', 1, 1313, 13)
  end)

  it('wrapper_metatable.delete', function()
    local wrapper_metatable = mk_wrapper_metatable_mock('collector-mock')

    wrapper_metatable:delete('test-key')
    assert.spy(dict_mock.delete).was.called_with('collector_mock¦test-key')
  end)

  it('wrapper_metatable.incr', function()
    local wrapper_metatable = mk_wrapper_metatable_mock('collector-mock')

    wrapper_metatable:incr('test-key', 13)
    assert.spy(dict_mock.incr).was.called_with('collector_mock¦test-key', 13)
  end)

  it('wrapper_metatable.safe_incr', function()
    local wrapper_metatable = mk_wrapper_metatable_mock('collector-mock')

    wrapper_metatable:safe_incr('test-key', 13)
    assert.spy(dict_mock.safe_incr).was.called_with('collector_mock¦test-key', 13)
  end)

  it('wrapper_metatable.mean_add [non existent]', function()
    local wrapper_metatable = mk_wrapper_metatable_mock('collector-mock')

    stub.new(dict_mock, 'get').on_call_with('collector_mock¦test-key').returns(nil, 0)

    wrapper_metatable:mean_add('test-key', 13)
    assert.spy(dict_mock.get).was.called_with('collector_mock¦test-key')
    assert.spy(dict_mock.set).was.called_with('collector_mock¦test-key', 13, nil, 1)

    dict_mock.get:revert()
  end)

  it('wrapper_metatable.mean_add [existent]', function()
    local wrapper_metatable = mk_wrapper_metatable_mock('collector-mock')

    stub.new(dict_mock, 'get').on_call_with('collector_mock¦test-key').returns(4, 2)

    wrapper_metatable:mean_add('test-key', 1)
    assert.spy(dict_mock.get).was.called_with('collector_mock¦test-key')
    assert.spy(dict_mock.set).was.called_with('collector_mock¦test-key', 3, nil, 3)

    dict_mock.get:revert()
  end)

  it('wrapper_metatable.mean_flush [non existent]', function()
    local wrapper_metatable = mk_wrapper_metatable_mock('collector-mock')

    stub.new(dict_mock, 'get').on_call_with('collector_mock¦test-key').returns(nil, 0)

    wrapper_metatable:mean_flush('test-key')
    assert.spy(dict_mock.get).was.called_with('collector_mock¦test-key')
    assert.spy(dict_mock.set).was.called_with('collector_mock¦test-key', 0, 0, 0)

    dict_mock.get:revert()
  end)

  it('wrapper_metatable.mean_flush [existent]', function()
    local wrapper_metatable = mk_wrapper_metatable_mock('collector-mock')

    stub.new(dict_mock, 'get').on_call_with('collector_mock¦test-key').returns(7, 7)

    wrapper_metatable:mean_flush('test-key')
    assert.spy(dict_mock.get).was.called_with('collector_mock¦test-key')
    assert.spy(dict_mock.set).was.called_with('collector_mock¦test-key', 7, 0, 1)

    dict_mock.get:revert()
  end)

  it('wrapper_metatable.mean_flush [existent, zero]', function()
    local wrapper_metatable = mk_wrapper_metatable_mock('collector-mock')

    stub.new(dict_mock, 'get').on_call_with('collector_mock¦test-key').returns(0, 1)

    wrapper_metatable:mean_flush('test-key')
    assert.spy(dict_mock.get).was.called_with('collector_mock¦test-key')
    assert.spy(dict_mock.set).was.called_with('collector_mock¦test-key', 0, 0, 0)

    dict_mock.get:revert()
  end)

  it('wrapper_metatable.cyclic_incr', function()
    local wrapper_metatable = mk_wrapper_metatable_mock('collector-mock')

    wrapper_metatable:cyclic_incr('test-key', 7)
    assert.spy(dict_mock.safe_incr).was.called_with('collector_mock¦test-key^^next^^', 7)
  end)

  it('wrapper_metatable.cyclic_flush [non existent]', function()
    local wrapper_metatable = mk_wrapper_metatable_mock('collector-mock')

    stub.new(dict_mock, 'get').on_call_with('collector_mock¦test-key^^next^^').returns(nil, 0)

    wrapper_metatable:cyclic_flush('test-key')
    assert.spy(dict_mock.get).was.called_with('collector_mock¦test-key^^next^^')
    assert.spy(dict_mock.delete).was.called_with('collector_mock¦test-key^^next^^')
    assert.spy(dict_mock.set).was.called_with('collector_mock¦test-key', 0, 0, 0)

    dict_mock.get:revert()
  end)

  it('wrapper_metatable.cyclic_flush [existent]', function()
    local wrapper_metatable = mk_wrapper_metatable_mock('collector-mock')

    stub.new(dict_mock, 'get').on_call_with('collector_mock¦test-key^^next^^').returns(7)

    wrapper_metatable:cyclic_flush('test-key')
    assert.spy(dict_mock.get).was.called_with('collector_mock¦test-key^^next^^')
    assert.spy(dict_mock.delete).was.called_with('collector_mock¦test-key^^next^^')
    assert.spy(dict_mock.set).was.called_with('collector_mock¦test-key', 7, 0, 0)

    dict_mock.get:revert()
  end)

  it('wrapper_metatable.cyclic_flush [non existent, window]', function()
    factory.set_window_size(10)

    local wrapper_metatable = mk_wrapper_metatable_mock('collector-mock')

    stub.new(dict_mock, 'get').on_call_with('collector_mock¦test-key^^next^^').returns(nil, 0)
    local sik = stub.new(Window.__private__.WindowItem, 'create_key')
    sik.on_call_with().returns('11111111111111111111111111111111')

    wrapper_metatable:cyclic_flush('test-key', true)
    assert.spy(dict_mock.get).was.called_with('collector_mock¦test-key^^next^^')
    assert.spy(dict_mock.delete).was.called_with('collector_mock¦test-key^^next^^')
    assert.spy(dict_mock.set).was.called_with('collector_mock¦test-key', 0, 0, 0)

    dict_mock.get:revert()
    sik:revert()
  end)

  it('wrapper_metatable.cyclic_flush [existent, window]', function()
    factory.set_window_size(10)

    local wrapper_metatable = mk_wrapper_metatable_mock('collector-mock')

    local test_data_wi = {
      ['11111111111111111111111111111111'] = {
        _key = '11111111111111111111111111111111',
        _payload = 7,
      },
      ['22222222222222222222222222222222'] = {
        _key = '22222222222222222222222222222222',
        _payload = 13,
      },
    }

    local test_data = {
      {
        wikey = '11111111111111111111111111111111',
        window = nil,
      },
      {
        wikey = '22222222222222222222222222222222',
        window = {
          _head = "11111111111111111111111111111111",
          _limit = 10,
          _name = "collector_mock¦test-key",
          _size = 1,
          _tail = "11111111111111111111111111111111",
        },
      },
    }

    local test_data_index;

    _G.ngx = mock({ now = function() end, md5 = function() end }, true)
    _G.ngx.now.on_call_with().returns(os.time())
    _G.ngx.md5.on_call_with(match._).invokes(function()
      return test_data[test_data_index].wikey
    end)

    --    stub.new(dict_mock, 'get').on_call_with('collector_mock¦test-key^^next^^').returns(7)
    stub.new(dict_mock, 'get').on_call_with(match._).invokes(function(key)
      local ret_val
      if key == 'collector_mock¦test-key^^next^^' then
        ret_val = test_data_wi[test_data[test_data_index].wikey]._payload
      elseif key:match('^WindowItem') then
        ret_val = test_data_wi[key:sub(12)]
      elseif key:match('^Window') then
        ret_val = test_data[test_data_index].window
      end
--      print('dict.get(' .. key .. ') => ' .. require 'inspect'(ret_val, { depth = 1 }))
      return ret_val
    end)
    stub.new(dict_mock, 'set').on_call_with(match._, match._).invokes(function(...)
--      print('dict.set(' .. require 'inspect'({ ... }, { depth = 2 }) .. ')')
    end)

    test_data_index = 1
    wrapper_metatable:cyclic_flush('test-key', true)
    test_data_index = 2
    wrapper_metatable:cyclic_flush('test-key', true)

    assert.spy(dict_mock.get).was.called_with('collector_mock¦test-key^^next^^')
    assert.spy(dict_mock.delete).was.called_with('collector_mock¦test-key^^next^^')
    assert.spy(dict_mock.set).was.called_with('collector_mock¦test-key', 7, 0, 0)
    assert.spy(dict_mock.set).was.called_with('collector_mock¦test-key', 10, 0, 0)

    dict_mock.get:revert()
  end)
end)
