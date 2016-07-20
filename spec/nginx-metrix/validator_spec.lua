require('spec.bootstrap')(assert)

describe('nginx-metrix.validator', function()
  local validator

  setup(function()
    validator = require 'nginx-metrix.validator'
  end)

  ---------------------------------------------------------------------------
  it('is_callable', function()
    pending('impelement it')
  end)

  it('assert_callable', function()
    pending('impelement it')
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
    pending('impelement it')
  end)

  it('is_grater', function()
    pending('impelement it')
  end)

  it('assert_grater', function()
    pending('impelement it')
  end)
end)
