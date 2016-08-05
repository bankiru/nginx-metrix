require('spec.bootstrap')(assert)

describe('nginx-metrix', function()
  local match = require 'luassert.match'

  local nginx_metrix

  setup(function()
    nginx_metrix = require 'nginx-metrix'
  end)

  ---------------------------------------------------------------------------
  it('version', function()
    assert.is_equal('2.0-dev', nginx_metrix._version)
  end)

  it('__call', function()
    stub(nginx_metrix, 'init')
    local options_emu = { some_option = 'some_value' }

    local module = nginx_metrix(options_emu)

    assert.spy(nginx_metrix.init).was_called_with(options_emu)
    assert.is_equal(nginx_metrix, module)

    nginx_metrix.init:revert()
  end)

  it('init', function()
    nginx_metrix._inited = nil

    stub(nginx_metrix, '_init_storage')
    stub(nginx_metrix, '_init_vhosts')
    stub(nginx_metrix, '_init_scheduler')
    stub(nginx_metrix, '_init_collectors')
    local options_emu = { some_option = 'some_value' }

    nginx_metrix.init(options_emu)

    assert.spy(nginx_metrix._init_storage).was_called_with(options_emu)
    assert.spy(nginx_metrix._init_vhosts).was_called_with(options_emu)
    assert.spy(nginx_metrix._init_scheduler).was_called_with(options_emu)
    assert.spy(nginx_metrix._init_collectors).was_called_with(options_emu)
    assert.is_true(nginx_metrix._inited)

    nginx_metrix._init_storage:revert()
    nginx_metrix._init_vhosts:revert()
    nginx_metrix._init_scheduler:revert()
    nginx_metrix._init_collectors:revert()
  end)

  it('init handles error', function()
    nginx_metrix._inited = nil

    stub(nginx_metrix, '_init_storage')
    stub(nginx_metrix, '_init_vhosts')
    stub(nginx_metrix, '_init_scheduler')
    stub(nginx_metrix, '_init_collectors')

    nginx_metrix._init_storage.on_call_with({}).invokes(function() error('_init_storage error') end)

    local logger_bak = nginx_metrix._logger
    nginx_metrix._logger = mock({ err = function() end })

    assert.has_no_error(function()
      nginx_metrix.init({})
    end)

    assert.spy(nginx_metrix._init_storage).was_called_with({})
    assert.spy(nginx_metrix._init_storage).was_called(1)
    assert.spy(nginx_metrix._init_vhosts).was_not_called()
    assert.spy(nginx_metrix._init_scheduler).was_not_called()
    assert.spy(nginx_metrix._init_collectors).was_not_called()
    assert.spy(nginx_metrix._logger.err).was_called_with(nginx_metrix._logger, 'Init failed. Metrix disabled.', match.matches('_init_storage error'))
    assert.is_false(nginx_metrix._inited)

    nginx_metrix._logger = logger_bak
    nginx_metrix._init_storage:revert()
    nginx_metrix._init_vhosts:revert()
    nginx_metrix._init_scheduler:revert()
    nginx_metrix._init_collectors:revert()
  end)

  it('_init_storage', function()
    local storage_emu = { 'storage' }
    local storage_module_mock = spy.new(function() return storage_emu end)
    local options_emu = { some_option = 'some_value' }

    package.loaded['nginx-metrix.storage'] = storage_module_mock

    nginx_metrix._init_storage(options_emu)

    assert.spy(storage_module_mock).was_called_with(options_emu)
    assert.spy(storage_module_mock).was_called(1)
    assert.is_same(storage_emu, nginx_metrix._storage)

    package.loaded['nginx-metrix.storage'] = nil
  end)

  it('_init_vhosts', function()
    local vhosts_emu = { 'vhosts' }
    local vhosts_module_mock = spy.new(function() return vhosts_emu end)
    local options_emu = { some_option = 'some_value' }
    local storage_emu = { 'storage' }

    package.loaded['nginx-metrix.vhosts'] = vhosts_module_mock

    nginx_metrix.storage = storage_emu
    nginx_metrix._init_vhosts(options_emu)

    assert.spy(vhosts_module_mock).was_called_with(options_emu, storage_emu)
    assert.spy(vhosts_module_mock).was_called(1)
    assert.is_same(vhosts_emu, nginx_metrix._vhosts)

    package.loaded['nginx-metrix.vhosts'] = nil
  end)

  it('_init_aggregator', function()
    local aggregator_emu = { 'aggregator' }
    local aggregator_module_mock = spy.new(function() return aggregator_emu end)
    local options_emu = { some_option = 'some_value' }
    local storage_emu = { 'storage' }

    package.loaded['nginx-metrix.aggregator'] = aggregator_module_mock

    nginx_metrix.storage = storage_emu
    nginx_metrix._init_aggregator(options_emu)

    assert.spy(aggregator_module_mock).was_called_with(options_emu, storage_emu)
    assert.spy(aggregator_module_mock).was_called(1)
    assert.is_same(aggregator_emu, nginx_metrix._aggregator)

    package.loaded['nginx-metrix.aggregator'] = nil
  end)

  it('_init_scheduler', function()
    local scheduler_emu = mock({ attach_action = function() end })
    local scheduler_module_mock = spy.new(function() return scheduler_emu end)
    local options_emu = { some_option = 'some_value' }
    local storage_emu = { 'storage' }

    package.loaded['nginx-metrix.scheduler'] = scheduler_module_mock

    nginx_metrix._aggregator = { aggregate = function() end }

    nginx_metrix._init_scheduler(options_emu, storage_emu)

    assert.spy(scheduler_module_mock).was_called_with(options_emu, storage_emu)
    assert.spy(scheduler_module_mock).was_called(1)
    assert.spy(scheduler_emu.attach_action).was_called_with('aggregator.aggregate', nginx_metrix._aggregator.aggregate)
    assert.spy(scheduler_emu.attach_action).was_called(1)
    assert.is_same(scheduler_emu, nginx_metrix._scheduler)

    package.loaded['nginx-metrix.scheduler'] = nil
    nginx_metrix._aggregator = nil
  end)

  it('_init_collectors', function()
    local collectors_emu = { 'collectors' }
    local collectors_module_mock = spy.new(function() return collectors_emu end)
    local options_emu = { some_option = 'some_value' }
    local storage_emu = { 'storage' }

    package.loaded['nginx-metrix.collectors'] = collectors_module_mock

    nginx_metrix.storage = storage_emu
    nginx_metrix._init_collectors(options_emu)

    assert.spy(collectors_module_mock).was_called_with(options_emu, storage_emu)
    assert.spy(collectors_module_mock).was_called(1)
    assert.is_same(collectors_emu, nginx_metrix._collectors)

    package.loaded['nginx-metrix.collectors'] = nil
  end)

  it('show', function()
    assert.has_no_error(function()
      nginx_metrix.show()
    end)
  end)
end)
