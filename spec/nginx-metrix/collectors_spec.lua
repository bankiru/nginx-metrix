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
end)
