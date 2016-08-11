require('spec.bootstrap')(assert)

describe('nginx-metrix.collectors', function()
  local collectors

  setup(function()
    collectors = require 'nginx-metrix.collectors'
  end)

  ---------------------------------------------------------------------------
  it('__call', function()
    stub(collectors, 'init')

    local options_emu = { some_option = 'some_value' }
    local storage_emu = { 'storage' }

    local result = collectors(options_emu, storage_emu)

    assert.spy(collectors.init).was_called_with(options_emu, storage_emu)
    assert.is_equal(collectors, result)

    collectors.init:revert()
  end)

  it('_exists', function()
    collectors._collectors = {}
    assert.is_false(collectors._exists('aa'))

    collectors._collectors = { aa = {} }
    assert.is_false(collectors._exists('aa'))

    collectors._collectors = { aa = {} }
    assert.is_true(collectors._exists({ name = 'aa' }))

    collectors._collectors = { aa = {} }
    assert.is_false(collectors._exists({ name = 'bb' }))

    collectors._collectors = {}
  end)

  it('_validate fails on invalid collector', function()
    assert.has_error(function()
      collectors._validate('aa')
    end, 'Collector must be a table. Got string.')

    assert.has_error(function()
      collectors._validate({ aaa = 'aaa' })
    end, 'Collector must contain a `name` property.')

    assert.has_error(function()
      collectors._validate({ name = 'aaa' })
    end, 'Collector<aaa>:collect must be a function or callable table. Got: nil.')

    assert.has_error(function()
      collectors._validate({ name = 'aaa', collect = function() end })
    end, 'Collector<aaa>:render must be a function or callable table. Got: nil.')

    assert.has_no_error(function()
      collectors._validate({ name = 'aaa', collect = function() end, render = function() end })
    end)
  end)

  it('register fails on invalid collector', function()
    stub(collectors, '_validate')

    collectors._validate.on_call_with({}).invokes(function() error('Invalid collector') end)

    assert.has_error(function()
      collectors.register({})
    end, 'Invalid collector')

    assert.spy(collectors._validate).was_called_with({})
    assert.spy(collectors._validate).was_called(1)

    collectors._validate:revert()
  end)

  it('register fails on existing collector', function()
    stub(collectors, '_exists')

    local test_collector = { name = 'aa', collect = function() end, render = function() end }

    collectors._exists.on_call_with(test_collector).returns(true)

    assert.has_error(function()
      collectors.register(test_collector)
    end, 'Collector<aa> already exists.')

    assert.spy(collectors._exists).was_called_with(test_collector)
    assert.spy(collectors._exists).was_called(1)

    collectors._exists:revert()
  end)

  it('init', function()
    stub(collectors, 'register')
    local storage_emu = { 'storage' }

    local collector_request_mock = { 'request' }
    local collector_status_mock = { 'status' }
    local collector_upstream_mock = { 'upstream' }

    package.loaded['nginx-metrix.collectors.request'] = collector_request_mock
    package.loaded['nginx-metrix.collectors.status'] = collector_status_mock
    package.loaded['nginx-metrix.collectors.upstream'] = collector_upstream_mock

    -- skip builtin collectors
    collectors.init({ skip_register_builtin_collectors = true }, storage_emu)
    assert.spy(collectors.register).was_not_called()
    assert.is_equal(storage_emu, collectors._storage)

    -- process builtin collectors
    collectors.init({}, storage_emu)
    assert.spy(collectors.register).was_called_with(collector_request_mock)
    assert.spy(collectors.register).was_called_with(collector_status_mock)
    assert.spy(collectors.register).was_called_with(collector_upstream_mock)
    assert.spy(collectors.register).was_called(3)

    collectors.register:revert()
    package.loaded['nginx-metrix.collectors.request'] = nil
    package.loaded['nginx-metrix.collectors.status'] = nil
    package.loaded['nginx-metrix.collectors.upstream'] = nil
  end)

  it('exec_all', function()
    collectors._collectors = { test = mock({ name = 'test', collect = function() end }) }

    collectors._logger = mock({ debug = function() end })

    collectors.exec_all('test')

    assert.spy(collectors._logger.debug).was_called_with(collectors._logger, 'Collector<test> called on phase `test`.')
    assert.spy(collectors._logger.debug).was_called(1)

    assert.spy(collectors._collectors.test.collect).was_called_with(collectors._collectors.test, 'test')
    assert.spy(collectors._collectors.test.collect).was_called(1)

    collectors._collectors = {}
  end)
end)
