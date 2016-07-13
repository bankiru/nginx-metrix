require('spec.bootstrap')(assert)

describe('nginx-metrix.vhosts', function()
  local vhosts

  setup(function()
    vhosts = require 'nginx-metrix.vhosts'
  end)

  ---------------------------------------------------------------------------
  it('__call', function()
    local stub_init = stub.new(vhosts, 'init')
    local options_emu = { some_option = 'some_value' }
    local storage_emu = { 'storage' }

    vhosts(options_emu, storage_emu)

    assert.spy(stub_init).was_called_with(options_emu, storage_emu)

    stub_init:revert()
  end)

  it('init', function()
    local stub_add = stub.new(vhosts, 'add')
    local storage_emu = { 'storage' }

    vhosts.init({}, storage_emu)
    assert.spy(stub_add).was_not_called()
    assert.is_equal(storage_emu, vhosts._storage)

    vhosts.init({ vhosts = nil }, storage_emu)
    assert.spy(stub_add).was_not_called()

    vhosts.init({ vhosts = false }, storage_emu)
    assert.spy(stub_add).was_not_called()

    assert.has_error(function()
      vhosts.init({ vhosts = 'invalid type' }, storage_emu)
    end, 'Invalid option `vhosts`. Expected table, got string.')
    assert.spy(stub_add).was_not_called()

    vhosts.init({ vhosts = {} }, storage_emu)
    assert.spy(stub_add).was_called_with({})

    vhosts.init({ vhosts = { 'vhost1' } }, storage_emu)
    assert.spy(stub_add).was_called_with({ 'vhost1' })

    assert.spy(stub_add).was_called(2)

    stub_add:revert()
  end)

  it('_store', function()
    local stub_storage = mock({ set = function() end })

    vhosts._storage = stub_storage
    vhosts._store()
    assert.spy(stub_storage.set).was_called_with(vhosts._vhosts_storage_key, vhosts._vhosts)
    assert.spy(stub_storage.set).was_called(1)
  end)

  it('_restore got not a table from storage', function()
    vhosts._vhosts = nil
    vhosts._storage = mock({ get = function() end }, true)
    vhosts._storage.get.on_call_with(vhosts._vhosts_storage_key).returns('invalid type')

    vhosts._restore()

    assert.spy(vhosts._storage.get).was_called_with(vhosts._vhosts_storage_key)
    assert.spy(vhosts._storage.get).was_called(1)
    assert.is_same({}, vhosts._vhosts)

    vhosts._storage = nil
  end)

  it('_restore got table from storage', function()
    vhosts._vhosts = nil
    vhosts._storage = mock({ get = function() end }, true)
    vhosts._storage.get.on_call_with(vhosts._vhosts_storage_key).returns({ 'vhost1' })

    vhosts._restore()

    assert.spy(vhosts._storage.get).was_called_with(vhosts._vhosts_storage_key)
    assert.spy(vhosts._storage.get).was_called(1)
    assert.is_same({ 'vhost1' }, vhosts._vhosts)

    vhosts._storage = nil
  end)

  it('add invalid vhost', function()
    stub(vhosts, '_restore')
    stub(vhosts, '_store')

    assert.has_error(function()
      vhosts.add(nil)
    end, 'Invalid argument for vhosts.add(). Expected table or string, got nil.')

    assert.spy(vhosts._restore).was_not_called()
    assert.spy(vhosts._store).was_not_called()

    vhosts._restore:revert()
    vhosts._store:revert()
  end)

  it('add already existing vhost', function()
    stub(vhosts, '_restore')
    stub(vhosts, '_store')

    vhosts._vhosts = { 'vhost1' }
    vhosts.add('vhost1')

    assert.spy(vhosts._restore).was_not_called()
    assert.spy(vhosts._store).was_not_called()

    vhosts._restore:revert()
    vhosts._store:revert()
  end)

  it('add already nonexisting vhost', function()
    stub(vhosts, '_restore')
    stub(vhosts, '_store')

    vhosts._vhosts = { 'vhost1' }
    vhosts.add('vhost2')

    assert.spy(vhosts._restore).was_called(1)
    assert.spy(vhosts._store).was_called(1)
    assert.is_same({ 'vhost1', 'vhost2' }, vhosts._vhosts)

    vhosts._restore:revert()
    vhosts._store:revert()
  end)

  it('list', function()
    stub(vhosts, '_restore')

    vhosts._vhosts = { 'vhost1' }
    local list = vhosts.list('vhost2')

    assert.spy(vhosts._restore).was_called(1)
    assert.is_same(vhosts._vhosts, list)

    vhosts._restore:revert()
  end)
end)
