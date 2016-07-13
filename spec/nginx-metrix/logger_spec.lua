require('spec.bootstrap')(assert)

describe('nginx-metrix.logger', function()
  local Logger

  setup(function()
    _G.ngx = {
      STDERR = 'STDERR',
      EMERG  = 'EMERG',
      ALERT  = 'ALERT',
      CRIT   = 'CRIT',
      ERR    = 'ERR',
      WARN   = 'WARN',
      NOTICE = 'NOTICE',
      INFO   = 'INFO',
      DEBUG  = 'DEBUG',
    }
    Logger = require 'nginx-metrix.logger'
  end)

  ---------------------------------------------------------------------------
  it('__call', function()
    stub(Logger, 'new')
    Logger.new.on_call_with('some-module-name').returns('some-logger')

    local logger = Logger('some-module-name')

    assert.spy(Logger.new).was_called_with('some-module-name')
    assert.is_equal('some-logger', logger)

    Logger.new:revert()
  end)

  it('new', function()
    local logger = Logger.new('some-module-name')

    assert.is_equal('some-module-name', logger.module_name)
    assert.is_equal(Logger, getmetatable(logger))
  end)

  it('log', function()
    _G.ngx.log = spy.new(function() end)

    local logger = Logger('test')

    logger:log(_G.ngx.INFO, 'test-msg-1')
    assert.spy(_G.ngx.log).was_called_with(_G.ngx.INFO, '[test] test-msg-1')

    logger:log(_G.ngx.INFO, { 'test-msg-2' })
    assert.spy(_G.ngx.log).was_called_with(_G.ngx.INFO, '[test] { "test-msg-2" }')

    logger:log(_G.ngx.INFO, 'test-msg-3', 'another-arg-1', 'another-arg-2')
    assert.spy(_G.ngx.log).was_called_with(_G.ngx.INFO, '[test] test-msg-3 :: { "another-arg-1", "another-arg-2" }')

    assert.spy(_G.ngx.log).was_called(3)

    _G.ngx.log = nil
  end)

  it('stderr', function()
    stub(Logger, 'log')

    local logger = Logger('test')
    logger:stderr('test-msg-1')
    logger:stderr('test-msg-2', {some = 'data'})

    assert.spy(Logger.log).was_called_with(logger, _G.ngx.STDERR, 'test-msg-1')
    assert.spy(Logger.log).was_called_with(logger, _G.ngx.STDERR, 'test-msg-2', {some = 'data'})
    assert.spy(Logger.log).was_called(2)

    Logger.log:revert()
  end)

  it('emerg', function()
    stub(Logger, 'log')

    local logger = Logger('test')
    logger:emerg('test-msg-1')
    logger:emerg('test-msg-2', {some = 'data'})

    assert.spy(Logger.log).was_called_with(logger, _G.ngx.EMERG, 'test-msg-1')
    assert.spy(Logger.log).was_called_with(logger, _G.ngx.EMERG, 'test-msg-2', {some = 'data'})
    assert.spy(Logger.log).was_called(2)

    Logger.log:revert()
  end)

  it('alert', function()
    stub(Logger, 'log')

    local logger = Logger('test')
    logger:alert('test-msg-1')
    logger:alert('test-msg-2', {some = 'data'})

    assert.spy(Logger.log).was_called_with(logger, _G.ngx.ALERT, 'test-msg-1')
    assert.spy(Logger.log).was_called_with(logger, _G.ngx.ALERT, 'test-msg-2', {some = 'data'})
    assert.spy(Logger.log).was_called(2)

    Logger.log:revert()
  end)

  it('crit', function()
    stub(Logger, 'log')

    local logger = Logger('test')
    logger:crit('test-msg-1')
    logger:crit('test-msg-2', {some = 'data'})

    assert.spy(Logger.log).was_called_with(logger, _G.ngx.CRIT, 'test-msg-1')
    assert.spy(Logger.log).was_called_with(logger, _G.ngx.CRIT, 'test-msg-2', {some = 'data'})
    assert.spy(Logger.log).was_called(2)

    Logger.log:revert()
  end)

  it('err', function()
    stub(Logger, 'log')

    local logger = Logger('test')
    logger:err('test-msg-1')
    logger:err('test-msg-2', {some = 'data'})

    assert.spy(Logger.log).was_called_with(logger, _G.ngx.ERR, 'test-msg-1')
    assert.spy(Logger.log).was_called_with(logger, _G.ngx.ERR, 'test-msg-2', {some = 'data'})
    assert.spy(Logger.log).was_called(2)

    Logger.log:revert()
  end)

  it('warn', function()
    stub(Logger, 'log')

    local logger = Logger('test')
    logger:warn('test-msg-1')
    logger:warn('test-msg-2', {some = 'data'})

    assert.spy(Logger.log).was_called_with(logger, _G.ngx.WARN, 'test-msg-1')
    assert.spy(Logger.log).was_called_with(logger, _G.ngx.WARN, 'test-msg-2', {some = 'data'})
    assert.spy(Logger.log).was_called(2)

    Logger.log:revert()
  end)

  it('notice', function()
    stub(Logger, 'log')

    local logger = Logger('test')
    logger:notice('test-msg-1')
    logger:notice('test-msg-2', {some = 'data'})

    assert.spy(Logger.log).was_called_with(logger, _G.ngx.NOTICE, 'test-msg-1')
    assert.spy(Logger.log).was_called_with(logger, _G.ngx.NOTICE, 'test-msg-2', {some = 'data'})
    assert.spy(Logger.log).was_called(2)

    Logger.log:revert()
  end)

  it('info', function()
    stub(Logger, 'log')

    local logger = Logger('test')
    logger:info('test-msg-1')
    logger:info('test-msg-2', {some = 'data'})

    assert.spy(Logger.log).was_called_with(logger, _G.ngx.INFO, 'test-msg-1')
    assert.spy(Logger.log).was_called_with(logger, _G.ngx.INFO, 'test-msg-2', {some = 'data'})
    assert.spy(Logger.log).was_called(2)

    Logger.log:revert()
  end)

  it('debug', function()
    stub(Logger, 'log')

    local logger = Logger('test')
    logger:debug('test-msg-1')
    logger:debug('test-msg-2', {some = 'data'})

    assert.spy(Logger.log).was_called_with(logger, _G.ngx.DEBUG, 'test-msg-1')
    assert.spy(Logger.log).was_called_with(logger, _G.ngx.DEBUG, 'test-msg-2', {some = 'data'})
    assert.spy(Logger.log).was_called(2)

    Logger.log:revert()
  end)
end)
