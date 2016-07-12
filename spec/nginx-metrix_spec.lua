require('spec.bootstrap')(assert)

describe('nginx-metrix', function()
  local nginx_metrix

  setup(function()
    nginx_metrix = require 'nginx-metrix'
  end)

  ---------------------------------------------------------------------------
  it('version', function()
    assert.is_equal('2.0-dev', nginx_metrix.version)
  end)

  it('__call', function()
    local stub_init = stub.new(nginx_metrix, 'init')
    local options = { some_option = 'some_value' }

    nginx_metrix(options)

    assert.spy(stub_init).was_called_with(options)

    stub_init:revert()
  end)

  it('init', function()
    local stub_init_storage = stub.new(nginx_metrix, 'init_storage')
    local stub_init_vhosts = stub.new(nginx_metrix, 'init_vhosts')
    local stub_init_builtin_collectors = stub.new(nginx_metrix, 'init_builtin_collectors')
    local options = { some_option = 'some_value' }

    nginx_metrix.init(options)

    assert.spy(stub_init_storage).was_called_with(options)
    assert.spy(stub_init_vhosts).was_called_with(options)
    assert.spy(stub_init_builtin_collectors).was_called_with(options)

    stub_init_storage:revert()
    stub_init_vhosts:revert()
    stub_init_builtin_collectors:revert()
  end)

  it('init_storage', function()
    local storage_emu = { 'storage' }
    local storage_module_mock = spy.new(function() return storage_emu end)
    local options = { some_option = 'some_value' }

    package.loaded['nginx-metrix.storage'] = storage_module_mock

    nginx_metrix.init_storage(options)

    assert.spy(storage_module_mock).was_called_with(options)
    assert.spy(storage_module_mock).was_called(1)
    assert.is_same(storage_emu, nginx_metrix.storage)

    package.loaded['nginx-metrix.storage'] = nil
  end)

  it('init_vhosts', function()
    local vhosts_emu = { 'vhosts' }
    local vhosts_module_mock = spy.new(function() return vhosts_emu end)
    local options = { some_option = 'some_value' }

    package.loaded['nginx-metrix.vhosts'] = vhosts_module_mock

    nginx_metrix.init_vhosts(options)

    assert.spy(vhosts_module_mock).was_called_with(options)
    assert.spy(vhosts_module_mock).was_called(1)
    assert.is_same(vhosts_emu, nginx_metrix.vhosts)

    package.loaded['nginx-metrix.vhosts'] = nil
  end)

  it('init_builtin_collectors', function()
    local collector_request_mock = { 'request' }
    local collector_status_mock = { 'status' }
    local collector_upstream_mock = { 'upstream' }

    package.loaded['nginx-metrix.collectors.request'] = collector_request_mock
    package.loaded['nginx-metrix.collectors.status'] = collector_status_mock
    package.loaded['nginx-metrix.collectors.upstream'] = collector_upstream_mock

    stub(nginx_metrix, 'register_collector')

    -- skip builtin collectors
    nginx_metrix.init_builtin_collectors({ skip_register_builtin_collectors = true })
    assert.spy(nginx_metrix.register_collector).was_not_called()

    -- process builtin collectors
    nginx_metrix.init_builtin_collectors({})
    assert.spy(nginx_metrix.register_collector).was_called_with(collector_request_mock)
    assert.spy(nginx_metrix.register_collector).was_called_with(collector_status_mock)
    assert.spy(nginx_metrix.register_collector).was_called_with(collector_upstream_mock)
    assert.spy(nginx_metrix.register_collector).was_called(3)

    nginx_metrix.register_collector:revert()
    package.loaded['nginx-metrix.collectors.request'] = nil
    package.loaded['nginx-metrix.collectors.status'] = nil
    package.loaded['nginx-metrix.collectors.upstream'] = nil
  end)
end)
