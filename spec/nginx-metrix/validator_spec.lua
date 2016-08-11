require('spec.bootstrap')(assert)

describe('nginx-metrix.validator', function()
  local validator

  setup(function()
    validator = require 'nginx-metrix.validator'
  end)

  ---------------------------------------------------------------------------
  it('is_callable', function()
    local test_callable

    test_callable = function() end
    assert.is_true(validator.is_callable(test_callable))

    test_callable = setmetatable({}, { __call = function() end })
    assert.is_true(validator.is_callable(test_callable))

    test_callable = setmetatable({}, { __call = setmetatable({}, { __call = function() end }) })
    assert.is_true(validator.is_callable(test_callable))

    test_callable = nil
    assert.is_false(validator.is_callable(test_callable))

    test_callable = 'string'
    assert.is_false(validator.is_callable(test_callable))

    test_callable = -1
    assert.is_false(validator.is_callable(test_callable))

    test_callable = {}
    assert.is_false(validator.is_callable(test_callable))
  end)

  it('assert_callable', function()
    assert.has_no_error(function()
      validator.assert_callable(function() end)
    end)
    assert.has_error(function()
      validator.assert_callable(nil)
    end)
  end)

  it('is_number', function()
    assert.is_true(validator.is_number(1))
    assert.is_true(validator.is_number(-1))
    assert.is_true(validator.is_number(0))
    assert.is_false(validator.is_number('0'))
    assert.is_false(validator.is_number(nil))
    assert.is_false(validator.is_number({}))
  end)

  it('assert_number', function()
    assert.has_no_error(function()
      validator.assert_number(7)
    end)
    assert.has_error(function()
      validator.assert_number(nil)
    end)
  end)

  it('is_grater', function()
    assert.is_true(validator.is_grater(0, -1))
    assert.is_false(validator.is_grater(3, 7))
    assert.has_error(function()
      validator.is_grater(13, nil)
    end)
  end)

  it('assert_grater', function()
    assert.has_no_error(function()
      validator.assert_grater(7, 1)
    end)
    assert.has_error(function()
      validator.assert_grater(13, nil)
    end)
    assert.has_error(function()
      validator.assert_grater(7, 13)
    end)
  end)
end)
