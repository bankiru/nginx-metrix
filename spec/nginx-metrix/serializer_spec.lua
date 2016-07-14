require('spec.bootstrap')(assert)

describe('serializer', function()

  local serializer = require 'nginx-metrix.serializer'

  it('serialize scalar values', function()
    local expected_value
    local actual_value

    expected_value = 'is string'
    actual_value = serializer.serialize(expected_value)
    assert.is_equal(expected_value, actual_value)

    expected_value = 123456
    actual_value = serializer.serialize(expected_value)
    assert.is_equal(expected_value, actual_value)
  end)

  it('unserialize scalar values', function()
    local expected_value
    local actual_value

    expected_value = 'is string'
    actual_value = serializer.unserialize(expected_value)
    assert.is_equal(expected_value, actual_value)

    expected_value = 123456
    actual_value = serializer.unserialize(expected_value)
    assert.is_equal(expected_value, actual_value)
  end)

  it('serialize table', function()
    local test_value
    local expected_value
    local actual_value

    test_value = { [[an item]] }
    expected_value = '@@lua_table@@["an item"]'
    actual_value = serializer.serialize(test_value)
    assert.is_equal(expected_value, actual_value)

    test_value = { key = [[an item]] }
    expected_value = '@@lua_table@@{"key":"an item"}'
    actual_value = serializer.serialize(test_value)
    assert.is_equal(expected_value, actual_value)
  end)

  it('unserialize table', function()
    local test_value
    local expected_value
    local actual_value

    test_value = '@@lua_table@@["an item"]'
    expected_value = { [[an item]] }
    actual_value = serializer.unserialize(test_value)
    assert.is_same(expected_value, actual_value)

    test_value = '@@lua_table@@{"key":"an item"}'
    expected_value = { key = [[an item]] }
    actual_value = serializer.unserialize(test_value)
    assert.is_same(expected_value, actual_value)
  end)

  it('unserialize handle error', function()
    local logger_bak = serializer._logger

    serializer._logger = mock({ err = function() end })

    local actual_value = serializer.unserialize('@@lua_table@@{invalid data]')

    assert.spy(serializer._logger.err).was_called_with(serializer._logger, "Can not unserialize value: '}' expected at line 1, column 2", "@@lua_table@@{invalid data]")
    assert.spy(serializer._logger.err).was_called(1)
    assert.is_same('@@lua_table@@{invalid data]', actual_value)

    serializer._logger = logger_bak
  end)
end)
