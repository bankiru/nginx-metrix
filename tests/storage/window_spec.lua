require('tests.bootstrap')(assert)

describe('storage.window', function()
  local match
  local dict_mock
  local Window

  setup(function()
    match = require 'luassert.match'

    package.loaded['nginx-metrix.storage.dict'] = nil
    dict_mock = mock(require 'nginx-metrix.storage.dict', true)
    package.loaded['nginx-metrix.storage.dict'] = dict_mock
  end)

  teardown(function()
    mock.revert(dict_mock)
    package.loaded['nginx-metrix.storage.dict'] = nil
    package.loaded['nginx-metrix.storage.window'] = nil
  end)

  before_each(function()
    Window = require 'nginx-metrix.storage.window'
  end)

  after_each(function()
    mock.clear(dict_mock)
    dict_mock.get:revert()
    stub.new(dict_mock, 'get')
    dict_mock.set:revert()
    stub.new(dict_mock, 'set')
    _G.ngx = nil
    package.loaded['nginx-metrix.storage.window'] = nil
  end)

  -- Window Item --
  it('WindowItem create key', function()
    _G.ngx = mock({ now = function() end, md5 = function() end }, true)
    _G.ngx.now.on_call_with().returns(os.time())
    _G.ngx.md5.on_call_with(match._).returns('0123456789AbCdEf0123456789aBcDeF')

    local key = Window.__private__.WindowItem.create_key('payload')
    assert.spy(_G.ngx.md5).was.called_with(match.has_match('^%d+%.%d+ %d+%.%d+$'))
    assert.spy(_G.ngx.md5).was.called(1)
    assert.is_equals(32, key:len())
    assert.matches('^[a-fA-F0-9]+$', key)
  end)

  it('WindowItem new', function()
    local sk = stub.new(Window.__private__.WindowItem, 'create_key')
    local ss = stub.new(Window.__private__.WindowItem, 'store')

    sk.on_call_with().returns('0123456789AbCdEf0123456789aBcDeF')

    local windowItem = Window.__private__.WindowItem.new('payload')

    assert.spy(sk).was.called(1)
    assert.spy(ss).was.called_with(windowItem)
    assert.spy(ss).was.called(1)

    assert.is_table(windowItem)

    assert.is_string(windowItem._key)
    assert.is_equals(32, windowItem._key:len())
    assert.matches('^[a-fA-F0-9]+$', windowItem._key)

    assert.is_equals('payload', windowItem._payload)

    assert.is_nil(windowItem._next)

    assert.is_table(getmetatable(windowItem))
    assert.is_equals(Window.__private__.WindowItem, getmetatable(windowItem))

    sk:revert()
    ss:revert()
  end)

  it('WindowItem store', function()
    local sk = stub.new(Window.__private__.WindowItem, 'create_key')

    sk.on_call_with().returns('0123456789AbCdEf0123456789aBcDeF')

    local windowItem = Window.__private__.WindowItem.new('payload')

    assert.spy(dict_mock.set).was.called_with('WindowItem^0123456789AbCdEf0123456789aBcDeF', windowItem)
    assert.spy(dict_mock.set).was.called(1)

    sk:revert()
  end)

  it('WindowItem restore', function()
    dict_mock.get.on_call_with('WindowItem^NINEXISTENTITEMKEY').returns(nil, 0)
    local windowItem0 = Window.__private__.WindowItem.restore('NINEXISTENTITEMKEY')
    assert.spy(dict_mock.get).was.called_with('WindowItem^NINEXISTENTITEMKEY')
    assert.is_nil(windowItem0)

    dict_mock.get.on_call_with('WindowItem^0123456789AbCdEf0123456789aBcDeF').returns({ _key = '0123456789AbCdEf0123456789aBcDeF', _payload = 'payload', _next = nil })
    local windowItem = Window.__private__.WindowItem.restore('0123456789AbCdEf0123456789aBcDeF')
    assert.spy(dict_mock.get).was.called_with('WindowItem^0123456789AbCdEf0123456789aBcDeF')
    assert.is_table(windowItem)
    assert.is_equals('0123456789AbCdEf0123456789aBcDeF', windowItem._key)
    assert.is_equals('payload', windowItem._payload)
    assert.is_nil(windowItem._next)
    assert.is_table(getmetatable(windowItem))

    assert.spy(dict_mock.get).was.called(2)
  end)

  it('WindowItem key getter', function()
    local sk = stub.new(Window.__private__.WindowItem, 'create_key')
    local ss = stub.new(Window.__private__.WindowItem, 'store')

    sk.on_call_with().returns('0123456789AbCdEf0123456789aBcDeF')

    local windowItem = Window.__private__.WindowItem.new('payload')

    assert.spy(sk).was.called(1)
    assert.spy(ss).was.called_with(windowItem)
    assert.spy(ss).was.called(1)

    assert.is_table(windowItem)

    assert.is_equals('0123456789AbCdEf0123456789aBcDeF', windowItem:key())

    sk:revert()
    ss:revert()
  end)

  it('WindowItem payload getter', function()
    local sk = stub.new(Window.__private__.WindowItem, 'create_key')
    local ss = stub.new(Window.__private__.WindowItem, 'store')

    sk.on_call_with().returns('0123456789AbCdEf0123456789aBcDeF')

    local windowItem = Window.__private__.WindowItem.new('payload')

    assert.spy(sk).was.called(1)
    assert.spy(ss).was.called_with(windowItem)
    assert.spy(ss).was.called(1)

    assert.is_table(windowItem)

    assert.is_equals('payload', windowItem:payload())

    sk:revert()
    ss:revert()
  end)

  it('WindowItem next getter and setter', function()
    local sk = stub.new(Window.__private__.WindowItem, 'create_key')
    local ss = stub.new(Window.__private__.WindowItem, 'store')
    local sr = stub.new(Window.__private__.WindowItem, 'restore')

    sk.on_call_with().returns('11111111111111111111111111111111')
    local windowItem1 = Window.__private__.WindowItem.new('payload 1')
    assert.spy(ss).was.called_with(windowItem1)

    assert.is_nil(windowItem1:next())

    sk.on_call_with().returns('22222222222222222222222222222222')
    local windowItem2 = Window.__private__.WindowItem.new('payload 2')
    assert.spy(ss).was.called_with(windowItem2)

    windowItem1:next(windowItem2)
    assert.spy(ss).was.called_with(windowItem1)
    assert.is_equals(windowItem2._key, windowItem1._next)

    sr.on_call_with(windowItem2._key).returns(windowItem2)
    local nextItem = windowItem1:next()
    assert.spy(sr).was.called_with(windowItem2._key)
    assert.is_same(windowItem2, nextItem)

    assert.spy(sk).was.called(2)
    assert.spy(ss).was.called(3)
    assert.spy(sr).was.called(1)

    sk:revert()
    ss:revert()
  end)
  -- Window Item --

  -- Window --
  it('Window open new', function()
    dict_mock.get.on_call_with('Window^test-window').returns(nil)

    local window = Window.open('test-window', 3)
    assert.is_table(window)
    assert.is_equals('test-window', window._name)
    assert.is_equals(3, window._limit)
    assert.is_equals(0, window._size)
    assert.is_nil(window._head)
    assert.is_nil(window._tail)
    assert.is_table(getmetatable(window))
    assert.is_equals(Window, getmetatable(window))
  end)

  it('Window open existent', function()
    dict_mock.get.on_call_with('Window^test-window').returns({ _name = 'test-window', _limit = 4, _size = 2, _head = '11111111111111111111111111111111', _tail = '22222222222222222222222222222222' })

    local window = Window.open('test-window', 3)
    assert.is_table(window)
    assert.is_equals('test-window', window._name)
    assert.is_equals(4, window._limit)
    assert.is_equals(2, window._size)
    assert.is_equals('11111111111111111111111111111111', window._head)
    assert.is_equals('22222222222222222222222222222222', window._tail)
    assert.is_table(getmetatable(window))
    assert.is_equals(Window, getmetatable(window))
  end)

  it('Window store', function()
    dict_mock.get.on_call_with('Window^test-window').returns({ _name = 'test-window', _limit = 4, _size = 2, _head = '11111111111111111111111111111111', _tail = '22222222222222222222222222222222' })

    local window = Window.open('test-window', 3)
    window:store()

    assert.spy(dict_mock.set).was.called_with('Window^test-window', window)
    assert.spy(dict_mock.set).was.called(1)
  end)

  it('Window push without displacement #1', function()
    dict_mock.get.on_call_with('Window^test-window').returns(nil)
    local sik = stub.new(Window.__private__.WindowItem, 'create_key')
    local sis = stub.new(Window.__private__.WindowItem, 'store')
    local sir = stub.new(Window.__private__.WindowItem, 'restore')
    local sqs = stub.new(Window, 'store')
    local sqp = stub.new(Window, 'pop')

    sik.on_call_with().returns('0123456789AbCdEf0123456789aBcDeF')

    local window = Window.open('test-window', 2)

    window:push(1)

    assert.spy(sqs).was.called_with(window)
    assert.spy(sqp).was_not.called()
    assert.spy(sir).was_not.called()
    assert.is_equals(1, window:len())

    sik:revert()
    sis:revert()
    sir:revert()
    sqs:revert()
    sqp:revert()
  end)

  it('Window push without displacement #2', function()
    dict_mock.get.on_call_with('Window^test-window').returns({ _name = 'test-window', _limit = 2, _size = 1, _head = '11111111111111111111111111111111', _tail = '11111111111111111111111111111111' })

    local sis = stub.new(Window.__private__.WindowItem, 'store')
    local sir = stub.new(Window.__private__.WindowItem, 'restore')
    local sqs = stub.new(Window, 'store')
    local sqp = stub.new(Window, 'pop')

    local sik0 = stub.new(Window.__private__.WindowItem, 'create_key')
    sik0.on_call_with().returns('11111111111111111111111111111111')
    local item_mock = Window.__private__.WindowItem.new('payload')
    spy.on(item_mock, 'next')
    sik0:revert();

    local sik = stub.new(Window.__private__.WindowItem, 'create_key')
    sir.on_call_with('11111111111111111111111111111111').returns(item_mock)

    sik.on_call_with().returns('0123456789AbCdEf0123456789aBcDeF')

    local window = Window.open('test-window', 2)

    window:push(1)

    assert.spy(sqs).was.called_with(window)
    assert.spy(sqp).was_not.called()
    assert.spy(sir).was.called_with('11111111111111111111111111111111')
    assert.spy(sir).was.called(1)
    assert.spy(item_mock.next).was.called(1)
    assert.is_equals(2, window:len())
    assert.is_equals('0123456789AbCdEf0123456789aBcDeF', window._tail)

    sik:revert()
    sis:revert()
    sir:revert()
    sqs:revert()
    sqp:revert()
  end)

  it('Window push with displacement', function()
    dict_mock.get.on_call_with('Window^test-window').returns(nil)
    local window = Window.open('test-window', 2)

    local sik = stub.new(Window.__private__.WindowItem, 'create_key')
    local sis = stub.new(Window.__private__.WindowItem, 'store')
    local sir = stub.new(Window.__private__.WindowItem, 'restore')
    local sqs = stub.new(window, 'store')
    local sqp = spy.on(window, 'pop')

    local key_gen_count = 0;
    sik.on_call_with().invokes(function()
      key_gen_count = key_gen_count + 1
      return '0000000000000000000000000000000' .. key_gen_count
    end)

    local items = {
      ['00000000000000000000000000000001'] = mock(Window.__private__.WindowItem.new('payload 1')),
      ['00000000000000000000000000000002'] = mock(Window.__private__.WindowItem.new('payload 2')),
      ['00000000000000000000000000000003'] = mock(Window.__private__.WindowItem.new('payload 3')),
    }
    key_gen_count = 0;

    sir.on_call_with(match._).invokes(function(key)
      return items[key]
    end)

    window:push(1)
    window:push(2)
    window:push(3)

    assert.spy(sqs).was.called_with(window)
    assert.spy(sqs).was.called(4)
    assert.spy(window.pop).was.called(1)
    assert.is_equals(2, window:len())

    sik:revert()
    sis:revert()
    sir:revert()
    sqs:revert()
    sqp:revert()
  end)

  it('Window pop', function()
    dict_mock.get.on_call_with('Window^test-window').returns({ _name = 'test-window', _limit = 2, _size = 1, _head = '11111111111111111111111111111111', _tail = '11111111111111111111111111111111' })

    local sik = stub.new(Window.__private__.WindowItem, 'create_key')
    local sir = stub.new(Window.__private__.WindowItem, 'restore')
    local sqs = stub.new(Window, 'store')
    sik.on_call_with().returns('11111111111111111111111111111111')

    local item_mock = mock(Window.__private__.WindowItem.new('payload'))
    sir.on_call_with('11111111111111111111111111111111').returns(item_mock)

    local window = Window.open('test-window', 2)

    local value = window:pop()

    assert.spy(sir).was.called_with('11111111111111111111111111111111')
    assert.spy(sir).was.called(1)
    assert.spy(sqs).was.called_with(window)
    assert.spy(sqs).was.called(1)
    assert.is_equals(0, window:len())
    assert.is_equals('payload', value)
    assert.is_nil(window._head)
    assert.is_nil(window._tail)

    sik:revert()
    sir:revert()
    sqs:revert()
  end)

  it('Window pop from empty', function()
    dict_mock.get.on_call_with('Window^test-window').returns(nil)
    local window = Window.open('test-window', 2)

    local item = window:pop()

    assert.is_nil(item)
  end)

  it('Window totable empty', function()
    dict_mock.get.on_call_with('Window^test-window').returns(nil)
    local window = Window.open('test-window', 2)

    local list = window:totable()

    assert.is_same({}, list)
  end)

  it('Window totable not empty', function()
    dict_mock.get.on_call_with('Window^test-window').returns({ _name = 'test-window', _limit = 2, _size = 1, _head = '11111111111111111111111111111111', _tail = '11111111111111111111111111111111' })
    local window = Window.open('test-window', 2)

    local sik = stub.new(Window.__private__.WindowItem, 'create_key')
    sik.on_call_with().returns('11111111111111111111111111111111')
    local item_mock = mock(Window.__private__.WindowItem.new('payload'))
    local sir = stub.new(Window.__private__.WindowItem, 'restore')
    sir.on_call_with('11111111111111111111111111111111').returns(item_mock)

    local list = window:totable()

    assert.is_same({'payload'}, list)

    sik:revert()
    sir:revert()
  end)
  -- /Window --
end)
