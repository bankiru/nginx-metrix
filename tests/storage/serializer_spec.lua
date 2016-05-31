require('tests.bootstrap')(assert)

describe('storage.serializer', function()

  local serializer = require 'nginx-metrix.storage.serializer'

  it('serialize scalar values', function()
    local expected_value
    local actual_value

    expected_value = 'is string'
    actual_value = serializer.serialize(expected_value)
    assert.are.equal(expected_value, actual_value)

    expected_value = 123456
    actual_value = serializer.serialize(expected_value)
    assert.are.equal(expected_value, actual_value)
  end)

  it('unserialize scalar values', function()
    local expected_value
    local actual_value

    expected_value = 'is string'
    actual_value = serializer.unserialize(expected_value)
    assert.are.equal(expected_value, actual_value)

    expected_value = 123456
    actual_value = serializer.unserialize(expected_value)
    assert.are.equal(expected_value, actual_value)
  end)

  it('serialize table', function()
    local test_value
    local expected_value
    local actual_value

    test_value = { [[an item]] }
    expected_value = '@@lua_table@@["an item"]'
    actual_value = serializer.serialize(test_value)
    assert.are.equal(expected_value, actual_value)

    test_value = { key = [[an item]] }
    expected_value = '@@lua_table@@{"key":"an item"}'
    actual_value = serializer.serialize(test_value)
    assert.are.equal(expected_value, actual_value)
  end)

  it('unserialize table', function()
    local test_value
    local expected_value
    local actual_value

    test_value = '@@lua_table@@["an item"]'
    expected_value = { [[an item]] }
    actual_value = serializer.unserialize(test_value)
    assert.are.same(expected_value, actual_value)

    test_value = '@@lua_table@@{"key":"an item"}'
    expected_value = { key = [[an item]] }
    actual_value = serializer.unserialize(test_value)
    assert.are.same(expected_value, actual_value)
  end)
end)
